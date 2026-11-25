"""Render a personal TOML profile as a Compose override (Ubuntu 24.04)."""
import hashlib
import json
import re
import subprocess
import sys
import tomllib
from pathlib import Path, PurePosixPath, PureWindowsPath

ROOT = Path(__file__).resolve().parent
PACKAGES = ["claude-desktop", "firefox-esr", "thunar", "fonts-noto-cjk"]


def render(config):
    if config.keys() - {"packages", "workdir", "shares"}:
        raise ValueError("Unknown top-level option")
    packages = config.get("packages", PACKAGES)
    if not isinstance(packages, list) or not all(isinstance(p, str) and re.fullmatch(r"[a-z0-9][a-z0-9.+-]*", p) for p in packages):
        raise ValueError("packages must be an array of Debian package names")
    workdir = config.get("workdir", "/workspace")
    legacy = ROOT / "hk-tailscale/export-dir.local"
    default_path = legacy.read_text().strip() if legacy.exists() else "/mnt/d/DockerCopy"
    shares = config.get("shares")
    volumes = []
    if "shares" not in config:
        volumes.append(bind(default_path, "/export", False))
    else:
        if not isinstance(shares, list):
            raise ValueError("shares must be an array")
        for share in shares:
            if not isinstance(share, dict) or share.keys() - {"windows", "container", "read_only"}:
                raise ValueError("Unknown share option")
            path = PureWindowsPath(share["windows"])
            if not re.fullmatch(r"[A-Za-z]:", path.drive) or not path.is_absolute() or ".." in path.parts:
                raise ValueError(f"Expected an absolute Windows drive path: {path}")
            source = subprocess.check_output(["wslpath", "-u", str(path)], text=True).rstrip("\n")
            if not Path(source).is_dir():
                raise ValueError(f"Create the shared Windows folder first: {path}")
            target = share["container"]
            dest = PurePosixPath(target)
            if (str(dest) != target or "$" in target or ".." in dest.parts or dest.root != "/"
                    or len(dest.parts) < 2 or dest.parts[1] not in {"export", "data", "projects", "mnt", "workspace"}
                    or target == "/workspace"):
                raise ValueError(f"Unsupported container share path: {target}")
            if any(dest == p or dest in p.parents or p in dest.parents for p in (PurePosixPath(v["target"]) for v in volumes)):
                raise ValueError(f"Overlapping mount: {target}")
            ro = share.get("read_only", False)
            if type(ro) is not bool:
                raise ValueError("read_only must be true or false")
            volumes.append(bind(source, target, ro))
    if workdir not in {"/workspace", "/home/node", *(v["target"] for v in volumes)}:
        raise ValueError("workdir must be /workspace, /home/node or a configured mount")
    service = {"build": {"args": {"WORKBENCH_PACKAGES": " ".join(packages)}},
               "working_dir": workdir, "volumes": volumes}
    signature = hashlib.sha256(json.dumps(service, sort_keys=True).encode()).hexdigest()
    service["labels"] = {"workbench.profile": signature}
    return {"services": {"browser": service}}


def bind(source, target, readonly):
    # Compose expands dollar signs even in JSON string values.
    return {"type": "bind", "source": source.replace("$", "$$"), "target": target.replace("$", "$$"),
            "read_only": readonly, "bind": {"create_host_path": False}}


if __name__ == "__main__":
    profile = ROOT / "workbench.local.toml"
    try:
        config = tomllib.loads(profile.read_text(encoding="utf-8-sig")) if profile.exists() else {}
        service = render(config)
        if sys.argv[1:] == ["--list"]:
            for volume in service["services"]["browser"]["volumes"]:
                source = subprocess.check_output(["wslpath", "-w", volume["source"].replace("$$", "$")], text=True).strip()
                mode = "read only" if volume["read_only"] else "read/write"
                print(f'{source} -> {volume["target"].replace("$$", "$")} ({mode})')
        else:
            print(json.dumps(service, ensure_ascii=False))
    except (ValueError, KeyError, TypeError, OSError, subprocess.CalledProcessError) as error:
        sys.exit(f"{profile.name}: {error}")
