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
    Write-SetupLog -Level 'ERROR' -Message $_.Exception.Message
    Write-Host "Operation failed. Local log: $diagnosticPath"
    exit 1
}

if ($ValidateOnly) {
    $requiredFiles = @(
        'Install-CodexScopedProxy.ps1',
        'Uninstall-CodexScopedProxy.ps1',
        'Start-CodexScopedProxy.ps1',
        'Start-CodexConnection.cmd'
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
    Restart = 'Create an optional Restart Codex Connection script? Type 1 for Yes or 2 for No (N)'
    Invalid = 'Invalid choice. Please try again.'
    Install = 'Installing Codex Connection...'
    Uninstall = 'Removing Codex Connection...'
}
$zh = ConvertFrom-Json @'
{
  "Language": "\u6309 Enter \u4f7f\u7528\u82f1\u8bed\uff0c\u6216\u8f93\u5165 ZH \u4f7f\u7528\u7b80\u4f53\u4e2d\u6587",
  "Action": "\u8f93\u5165 1 \u5b89\u88c5\uff0c\u8f93\u5165 2 \u5378\u8f7d",
  "Restart": "\u662f\u5426\u751f\u6210\u53ef\u9009\u7684\u201c\u91cd\u542f Codex Connection\u201d\u811a\u672c\uff1f\u8f93\u5165 1 \u751f\u6210\uff0c\u8f93\u5165 2 \u4e0d\u751f\u6210\uff08N\uff09",
  "Invalid": "\u8f93\u5165\u65e0\u6548\uff0c\u8bf7\u91cd\u8bd5\u3002",
  "Install": "\u6b63\u5728\u5b89\u88c5 Codex Connection...",
  "Uninstall": "\u6b63\u5728\u5378\u8f7d Codex Connection..."
}
'@

$languageChoice = (Read-Host $en.Language).Trim().ToUpperInvariant()
$text = if ($languageChoice -eq 'ZH') { $zh } else { $en }
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
        exit 0
    }
    exit 1
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
& (Join-Path $PSScriptRoot 'Install-CodexScopedProxy.ps1') -GenerateRestartScript:$generateRestart
if ($?) {
    Write-SetupLog -Level 'INFO' -Message 'INSTALL_COMPLETED'
    exit 0
}
exit 1
