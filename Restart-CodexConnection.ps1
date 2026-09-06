[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$logDirectory = Join-Path $PSScriptRoot 'logs'
$logPath = Join-Path $logDirectory 'restart.log'

function Write-RestartLog {
    param([Parameter(Mandatory = $true)][string]$Message)

    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }
    Add-Content -LiteralPath $logPath -Encoding UTF8 -Value ('{0} [RESTART] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message)
}

try {
    $running = @(Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue)
    foreach ($process in $running) {
        Stop-Process -Id $process.Id -Force
    }

    $deadline = (Get-Date).AddSeconds(15)
    while (@(Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue).Count -gt 0) {
        if ((Get-Date) -ge $deadline) {
            throw 'Timed out while waiting for Codex to close before restart.'
        }
        Start-Sleep -Milliseconds 250
    }

    & (Join-Path $PSScriptRoot 'Start-CodexScopedProxy.ps1')
    if ($LASTEXITCODE -ne 0) {
        throw 'The Codex start step failed after Codex closed. See launcher.log for details.'
    }
    Write-RestartLog 'RESTART_COMPLETED'
    exit 0
}
catch {
    Write-RestartLog "FAILED error=$($_.Exception.Message)"
    exit 1
}
