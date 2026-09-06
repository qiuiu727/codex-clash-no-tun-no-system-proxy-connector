[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$running = @(Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue)
foreach ($process in $running) {
    Stop-Process -Id $process.Id -Force
}
if ($running.Count -gt 0) {
    Start-Sleep -Seconds 2
}
& (Join-Path $PSScriptRoot 'Start-CodexScopedProxy.ps1')
exit $LASTEXITCODE
