param([switch]$Once)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class ClaudePasteWindow {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern uint GetClipboardSequenceNumber();
}
'@

function Test-ClaudeFocus {
    $window = [ClaudePasteWindow]::GetForegroundWindow()
    [uint32]$owner = 0
    [void][ClaudePasteWindow]::GetWindowThreadProcessId($window, [ref]$owner)
    $app = Get-Process -Id $owner -ErrorAction SilentlyContinue
    return $app -and $app.ProcessName -eq 'msrdc' -and $app.MainWindowTitle -like '*Claude*' -and $app.MainWindowHandle -eq $window
}

function Publish-Screenshot {
    $image = [Windows.Forms.Clipboard]::GetImage()
    if (!$image) { return }
    $png = New-Object IO.MemoryStream
    try {
        $image.Save($png, [Drawing.Imaging.ImageFormat]::Png)
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $digest = [Convert]::ToBase64String($sha.ComputeHash($png.ToArray())) } finally { $sha.Dispose() }
        if (!$Once -and $digest -eq $script:lastImage) { return }
        $start = New-Object Diagnostics.ProcessStartInfo
        $start.FileName = "$env:SystemRoot\System32\wsl.exe"
        $start.Arguments = '-d Ubuntu --exec /bin/sh -c "WAYLAND_DISPLAY=/mnt/wslg/runtime-dir/wayland-0 timeout 6 wl-copy --type image/png >/dev/null 2>&1"'
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $start.RedirectStandardInput = $true
        $child = [Diagnostics.Process]::Start($start)
        try {
            $png.Position = 0
            $png.CopyTo($child.StandardInput.BaseStream)
            $child.StandardInput.Close()
            if (!$child.WaitForExit(9000) -or $child.ExitCode -ne 0) { throw 'Publishing image/png failed.' }
        } finally { $child.Dispose() }
        $script:lastImage = $digest
    } finally { $png.Dispose(); $image.Dispose() }
}

if ($Once) { Publish-Screenshot; exit }
$created = $false
$mutex = [Threading.Mutex]::new($true, 'Local\ClaudeDockerScreenshotBridge', [ref]$created)
if (!$created) { $mutex.Dispose(); exit }
try {
    $lastSequence = -1
    while ($true) {
        $sequence = [ClaudePasteWindow]::GetClipboardSequenceNumber()
        if ($sequence -ne $lastSequence -and (Test-ClaudeFocus)) {
            try {
                if ([Windows.Forms.Clipboard]::ContainsImage()) { Publish-Screenshot } else { $script:lastImage = $null }
                $lastSequence = $sequence
            } catch { Start-Sleep -Seconds 1 }
        }
        Start-Sleep -Milliseconds 200
    }
} finally { $mutex.ReleaseMutex(); $mutex.Dispose() }
