[CmdletBinding()]
param(
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'

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
    Action = 'Type I to install or U to uninstall'
    Restart = 'Create an optional Restart Codex Connection script? Type Y for yes'
    Invalid = 'Invalid choice. Please try again.'
    Install = 'Installing Codex Connection...'
    Uninstall = 'Removing Codex Connection...'
}
$zh = ConvertFrom-Json @'
{
  "Language": "\u6309 Enter \u4f7f\u7528\u82f1\u8bed\uff0c\u6216\u8f93\u5165 ZH \u4f7f\u7528\u7b80\u4f53\u4e2d\u6587",
  "Action": "\u8f93\u5165 I \u5b89\u88c5\uff0c\u6216\u8f93\u5165 U \u5378\u8f7d",
  "Restart": "\u662f\u5426\u751f\u6210\u53ef\u9009\u7684\u201c\u91cd\u542f Codex Connection\u201d\u811a\u672c\uff1f\u8f93\u5165 Y \u786e\u8ba4",
  "Invalid": "\u8f93\u5165\u65e0\u6548\uff0c\u8bf7\u91cd\u8bd5\u3002",
  "Install": "\u6b63\u5728\u5b89\u88c5 Codex Connection...",
  "Uninstall": "\u6b63\u5728\u5378\u8f7d Codex Connection..."
}
'@

$languageChoice = (Read-Host $en.Language).Trim().ToUpperInvariant()
$text = if ($languageChoice -eq 'ZH') { $zh } else { $en }

while ($true) {
    $action = (Read-Host $text.Action).Trim().ToUpperInvariant()
    if ($action -in @('I', 'U')) { break }
    Write-Host $text.Invalid
}

if ($action -eq 'U') {
    Write-Host $text.Uninstall
    $uninstaller = Join-Path $PSScriptRoot 'Uninstall-CodexScopedProxy.ps1'
    if (Test-Path -LiteralPath $uninstaller -PathType Leaf) {
        & $uninstaller
    }
    else {
        $installedUninstaller = Join-Path $env:LOCALAPPDATA 'CodexConnection\Uninstall-CodexScopedProxy.ps1'
        & $installedUninstaller
    }
    if ($?) { exit 0 }
    exit 1
}

$restartChoice = (Read-Host $text.Restart).Trim().ToUpperInvariant()
$generateRestart = $restartChoice -eq 'Y'
Write-Host $text.Install
& (Join-Path $PSScriptRoot 'Install-CodexScopedProxy.ps1') -GenerateRestartScript:$generateRestart
if ($?) { exit 0 }
exit 1
