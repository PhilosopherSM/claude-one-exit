$ErrorActionPreference = 'Stop'
$docker = (Get-Command docker.exe -CommandType Application).Source

function Test-LinuxEngine {
    $ErrorActionPreference = 'Continue'
    & $docker --context desktop-linux version --format '{{.Server.Version}}' *> $null
    return $LASTEXITCODE -eq 0
}

if (Test-LinuxEngine) { exit 0 }

Write-Output 'Starting Docker Desktop...'
& $docker desktop start --timeout 120
$startCode = $LASTEXITCODE

# Desktop can report ready before its Linux engine answers the CLI.
$deadline = [DateTime]::UtcNow.AddSeconds(30)
do {
    if (Test-LinuxEngine) { exit 0 }
    Start-Sleep -Seconds 2
} while ([DateTime]::UtcNow -lt $deadline)

throw "Docker Desktop's Linux engine did not become ready (start exit code: $startCode)."
