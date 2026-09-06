[CmdletBinding()]
param(
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
$diagnosticDirectory = Join-Path $env:LOCALAPPDATA 'CodexConnection\logs'
$diagnosticPath = Join-Path $diagnosticDirectory 'setup.log'

function ConvertTo-SafeLogMessage {
    param([Parameter(Mandatory = $true)][string]$Message)

    $safe = $Message
    $safe = $safe -replace '(?i)(vless|vmess|trojan|ss)://\S+', '<redacted-node-uri>'
    $safe = $safe -replace '(?i)(token|secret|password)=\S+', '$1=<redacted>'
    return $safe
}

function Write-SetupLog {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not (Test-Path -LiteralPath $diagnosticDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $diagnosticDirectory -Force | Out-Null
    }
    $line = '{0} [SETUP] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, (ConvertTo-SafeLogMessage -Message $Message)
    Add-Content -LiteralPath $diagnosticPath -Encoding UTF8 -Value $line
}

trap {
    $safeMessage = ConvertTo-SafeLogMessage -Message $_.Exception.Message
    Write-SetupLog -Level 'ERROR' -Message $safeMessage
    Write-Host "FAILED: $safeMessage" -ForegroundColor Red
    Write-Host "Local log: $diagnosticPath"
    exit 1
}

if ($ValidateOnly) {
    $requiredFiles = @(
        'Install-CodexScopedProxy.ps1',
        'Uninstall-CodexScopedProxy.ps1',
        'Start-CodexScopedProxy.ps1',
        'Start-CodexConnection.cmd',
        'New-DesktopLaunchers.ps1',
        'CodexConnectionLauncher.exe'
    )
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $file) -PathType Leaf)) {
            throw "Required setup file is missing: $file"
        }
    }
    Write-Output 'Setup validation passed.'
    exit 0
}

$en = [pscustomobject]@{
    Language = 'Press Enter for English, or type ZH for Simplified Chinese'
    Action = 'Type 1 to install or 2 to uninstall'
    Restart = 'Create an optional Restart Codex Connection script? Type 1 for Yes or 2 for No'
    Invalid = 'Invalid choice. Please try again.'
    Install = 'Installing Codex Connection...'
    Uninstall = 'Removing Codex Connection...'
    InstallSuccess = 'SUCCESS: Codex Connection was installed. The portable launcher is on your Desktop and can be moved anywhere.'
    UninstallSuccess = 'SUCCESS: Codex Connection was removed.'
}
$zh = ConvertFrom-Json @'
{
  "Language": "\u6309 Enter \u4f7f\u7528\u82f1\u8bed\uff0c\u6216\u8f93\u5165 ZH \u4f7f\u7528\u7b80\u4f53\u4e2d\u6587",
  "Action": "\u8f93\u5165 1 \u5b89\u88c5\uff0c\u8f93\u5165 2 \u5378\u8f7d",
  "Restart": "\u662f\u5426\u751f\u6210\u53ef\u9009\u7684\u201c\u91cd\u542f Codex Connection\u201d\u811a\u672c\uff1f\u8f93\u5165 1 \u751f\u6210\uff0c\u8f93\u5165 2 \u4e0d\u751f\u6210",
  "Invalid": "\u8f93\u5165\u65e0\u6548\uff0c\u8bf7\u91cd\u8bd5\u3002",
  "Install": "\u6b63\u5728\u5b89\u88c5 Codex Connection...",
  "Uninstall": "\u6b63\u5728\u5378\u8f7d Codex Connection...",
  "InstallSuccess": "\u6210\u529f\uff1aCodex Connection \u5df2\u5b89\u88c5\u3002\u53ef\u79fb\u52a8\u7684\u542f\u52a8\u6587\u4ef6\u5df2\u521b\u5efa\u5728\u684c\u9762\u3002",
  "UninstallSuccess": "\u6210\u529f\uff1aCodex Connection \u5df2\u5378\u8f7d\u3002"
}
'@

$languageChoice = (Read-Host $en.Language).Trim().ToUpperInvariant()
$text = if ($languageChoice -eq 'ZH') { $zh } else { $en }
$languageCode = if ($languageChoice -eq 'ZH') { 'zh' } else { 'en' }
Write-SetupLog -Level 'INFO' -Message 'SETUP_STARTED'

while ($true) {
    $action = (Read-Host $text.Action).Trim().ToUpperInvariant()
    if ($action -in @('1', '2')) { break }
    Write-Host $text.Invalid
}

if ($action -eq '2') {
    Write-SetupLog -Level 'INFO' -Message 'UNINSTALL_REQUESTED'
    Write-Host $text.Uninstall
    $uninstaller = Join-Path $PSScriptRoot 'Uninstall-CodexScopedProxy.ps1'
    if (Test-Path -LiteralPath $uninstaller -PathType Leaf) {
        & $uninstaller
    }
    else {
        $installedUninstaller = Join-Path $env:LOCALAPPDATA 'CodexConnection\Uninstall-CodexScopedProxy.ps1'
        & $installedUninstaller
    }
    if ($?) {
        Write-SetupLog -Level 'INFO' -Message 'UNINSTALL_COMPLETED'
        Write-Host $text.UninstallSuccess -ForegroundColor Green
        exit 0
    }
    throw 'Uninstall command failed. See the local log for details.'
}

$restartChoice = (Read-Host $text.Restart).Trim().ToUpperInvariant()
while ($restartChoice -notin @('1', '2')) {
    Write-Host $text.Invalid
    $restartChoice = (Read-Host $text.Restart).Trim().ToUpperInvariant()
}
$generateRestart = $restartChoice -eq '1'
$installRequest = if ($generateRestart) { 'INSTALL_REQUESTED restart_script=yes' } else { 'INSTALL_REQUESTED restart_script=no' }
Write-SetupLog -Level 'INFO' -Message $installRequest
Write-Host $text.Install
& (Join-Path $PSScriptRoot 'Install-CodexScopedProxy.ps1') -GenerateRestartScript:$generateRestart -Language $languageCode
if ($?) {
    Write-SetupLog -Level 'INFO' -Message 'INSTALL_COMPLETED'
    Write-Host $text.InstallSuccess -ForegroundColor Green
    exit 0
}
throw 'Installer command failed. See the local log for details.'
