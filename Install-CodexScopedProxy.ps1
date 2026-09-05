[CmdletBinding()]
param(
    [switch]$LaunchAfterInstall
)

$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'CodexScopedProxyLauncher'
$sourceRoot = $PSScriptRoot
$filesToInstall = @(
    'Start-CodexScopedProxy.ps1',
    'New-TaskbarShortcut.ps1',
    'Remove-TaskbarShortcut.ps1',
    'Uninstall-CodexScopedProxy.ps1'
)

foreach ($file in $filesToInstall) {
    if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $file) -PathType Leaf)) {
        throw "Required installer file is missing: $file"
    }
}

New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
foreach ($file in $filesToInstall) {
    Copy-Item -LiteralPath (Join-Path $sourceRoot $file) -Destination (Join-Path $installRoot $file) -Force
}

& (Join-Path $installRoot 'Start-CodexScopedProxy.ps1') -DetectOnly
if ($LASTEXITCODE -ne 0) {
    throw 'Installation stopped because no working local HTTP proxy was detected. No system proxy, TUN, or subscription was changed.'
}

& (Join-Path $installRoot 'New-TaskbarShortcut.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'The launcher was installed, but the Start Menu shortcut could not be created.'
}

Write-Output "Installed to $installRoot"
Write-Output 'The local proxy endpoint was auto-detected and saved only in the ignored installation directory.'
Write-Output 'Pin the generated Start Menu shortcut to the taskbar if desired.'

if ($LaunchAfterInstall) {
    Start-Process -FilePath (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', (Join-Path $installRoot 'Start-CodexScopedProxy.ps1')) -WindowStyle Hidden
}
