$ErrorActionPreference = 'Stop'

$wsl = Join-Path $env:SystemRoot 'System32\wsl.exe'
$linuxPath = & $wsl -d Ubuntu --cd $PSScriptRoot --exec /usr/bin/realpath -e ./Open-Docker-App.sh
if ($LASTEXITCODE -ne 0 -or -not $linuxPath -or $linuxPath -match '["\r\n]') {
    throw 'Cannot resolve the shared launcher path in Ubuntu.'
}

$programs = [Environment]::GetFolderPath('Programs')
if (-not (Test-Path -LiteralPath $programs -PathType Container)) {
    throw 'Cannot locate the current user Start menu.'
}

$folder = Join-Path $programs 'Docker Apps'
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$links = New-Object -ComObject WScript.Shell
$apps = [ordered]@{ Claude = 'claude'; Firefox = 'firefox'; Terminal = 'terminal' }
$cmd = Join-Path $env:SystemRoot 'System32\cmd.exe'
$desktopLaunchers = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\hk-tailscale\desktop'))
foreach ($name in $apps.Keys) {
    $file = Join-Path $folder "$name (Docker).lnk"
    $legacyArguments = '-d Ubuntu --exec /usr/bin/bash "' + $linuxPath + '" ' + $apps[$name] + ' --wslg'
    $target = $wsl
    $arguments = $legacyArguments
    $description = "Open $name in the existing Docker container."
    if ($name -ne 'Terminal') {
        $launcher = Join-Path $desktopLaunchers "Reopen-$name.cmd"
        if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) {
            throw "Cannot find the Windows launcher: $launcher"
        }
        $target = $cmd
        $arguments = '/d /c ""' + $launcher + '""'
        $description = "Start Docker Desktop if needed and open $name in the Docker container."
    }
    $link = $links.CreateShortcut($file)
    $matchesNew = $link.TargetPath -eq $target -and $link.Arguments -eq $arguments
    $matchesLegacy = $link.TargetPath -eq $wsl -and $link.Arguments -eq $legacyArguments
    if ($name -ne 'Terminal') {
        $exe = if ($name -eq 'Firefox') { 'firefox-esr' } else { 'claude-desktop' }
        & docker.exe --context desktop-linux exec hk-browser-session-browser-1 sh -c 'command -v $1 >/dev/null || exit 42' sh $exe
        if ($LASTEXITCODE -eq 42) {
            if ((Test-Path -LiteralPath $file) -and ($matchesNew -or $matchesLegacy)) { Remove-Item -LiteralPath $file }
            continue
        }
        if ($LASTEXITCODE -ne 0) { throw "Cannot inspect installed applications." }
    }
    if ((Test-Path -LiteralPath $file) -and -not ($matchesNew -or $matchesLegacy)) {
        throw "Existing shortcut was not overwritten: $file"
    }
    if ($matchesNew -and $link.Description -eq $description) { continue }
    $link.TargetPath = $target
    $link.Arguments = $arguments
    $link.WorkingDirectory = $PSScriptRoot
    $link.Description = $description
    $link.Save()

    $saved = $links.CreateShortcut($file)
    if ($saved.TargetPath -ne $target -or $saved.Arguments -ne $arguments) {
        throw "Could not verify shortcut: $file"
    }
    Write-Output $file
}
