param([switch]$CheckOnly)

$ErrorActionPreference = 'Stop'
$docker = (Get-Command docker.exe -CommandType Application).Source
$wsl = Join-Path $env:SystemRoot 'System32\wsl.exe'
$shutdown = Join-Path $env:SystemRoot 'System32\shutdown.exe'

function Get-DesktopStatus {
    $raw = & $docker desktop status --format json 2>$null
    if ($LASTEXITCODE -eq 0) {
        return ($raw | ConvertFrom-Json -ErrorAction Stop).Status
    }
    if (-not (Get-Process -Name 'com.docker.backend','Docker Desktop' -ErrorAction SilentlyContinue)) {
        return 'stopped'
    }
    throw 'Could not verify Docker Desktop status.'
}

function Test-UbuntuRunning {
    $output = & $wsl --list --running --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Could not check which WSL distributions are running.' }
    $names = ((@($output) -join "`n") -replace '[\u0000\uFEFF]', '') -split '[\r\n]+'
    return (@($names | ForEach-Object { $_.Trim() }) -contains 'Ubuntu')
}

function Test-DesktopAppsOpen {
    $running = & $docker --context desktop-linux ps --format '{{.Names}}'
    if ($LASTEXITCODE -ne 0) { throw 'Could not check the local Docker containers.' }
    if ($running -notcontains 'hk-browser-session-browser-1') { return $false }
    $apps = & $docker --context desktop-linux top hk-browser-session-browser-1 -eo pid,comm
    if ($LASTEXITCODE -ne 0) { throw 'Could not check whether Claude or Firefox is open.' }
    return [bool](@($apps) -match '^\s*\d+\s+(claude-desktop|firefox(-esr)?)\s*$')
}

if ($CheckOnly) {
    $status = Get-DesktopStatus
    Write-Output "Docker Desktop: $status"
    Write-Output "Ubuntu running: $(Test-UbuntuRunning)"
    if ($status -eq 'running') { Write-Output "Claude or Firefox open: $(Test-DesktopAppsOpen)" }
    Write-Output 'Read-only check: no shutdown actions taken.'
    exit 0
}

Add-Type -AssemblyName System.Windows.Forms
$title = 'Safe Shutdown'
$message = "Save your work and quit Claude and Firefox normally first.`n`nContinue to stop Docker Desktop, shut down Ubuntu, then turn off Windows?"
$answer = [System.Windows.Forms.MessageBox]::Show($message, $title, 'YesNo', 'Warning', 'Button2')
if ($answer -ne 'Yes') { exit 0 }

try {
    $status = Get-DesktopStatus
    if ($status -notin 'running','stopped') {
        throw "Docker Desktop is $status. Wait until it has started or stopped, then try again."
    }
    if ($status -eq 'running') {
        if (Test-DesktopAppsOpen) {
            throw 'Claude or Firefox is still running. Use the app menu to Quit, then double-click Safe Shutdown again.'
        }
        Write-Host 'Stopping Docker Desktop...'
        & $docker desktop stop --timeout 120
        if ($LASTEXITCODE -ne 0) { throw 'Docker Desktop did not stop normally.' }
        if ((Get-DesktopStatus) -ne 'stopped') { throw 'Docker Desktop is still running.' }
    }

    if (Test-UbuntuRunning) {
        Write-Host 'Shutting down Ubuntu...'
        & $wsl -d Ubuntu -u root -- systemctl --no-block --no-wall poweroff
        if ($LASTEXITCODE -ne 0 -and (Test-UbuntuRunning)) { throw 'Ubuntu did not accept a normal shutdown.' }
        $deadline = [DateTime]::UtcNow.AddSeconds(45)
        while ((Test-UbuntuRunning) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Seconds 2 }
        if (Test-UbuntuRunning) { throw 'Ubuntu is still running.' }
    }

    if ((Get-DesktopStatus) -ne 'stopped') { throw 'Docker Desktop restarted during shutdown.' }
    & $shutdown /s /t 0
    if ($LASTEXITCODE -ne 0) { throw 'Windows did not accept the shutdown request.' }
} catch {
    [void][System.Windows.Forms.MessageBox]::Show("Windows was not shut down.`n`n$($_.Exception.Message)", $title, 'OK', 'Error')
    exit 1
}
