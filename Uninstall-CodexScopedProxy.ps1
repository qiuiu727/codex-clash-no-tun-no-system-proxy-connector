[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'CodexConnection'
$expectedRoot = [System.IO.Path]::GetFullPath($installRoot).TrimEnd('\')
$logDirectory = Join-Path $installRoot 'logs'
$logPath = Join-Path $logDirectory 'uninstaller.log'
$startMenuDirectory = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$taskbarDirectory = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
$desktopDirectory = [Environment]::GetFolderPath('DesktopDirectory')
if ([string]::IsNullOrWhiteSpace($desktopDirectory)) {
    $desktopDirectory = Join-Path $env:USERPROFILE 'Desktop'
}

function Write-UninstallerLog {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }
    Add-Content -LiteralPath $logPath -Encoding UTF8 -Value ('{0} [UNINSTALLER] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message)
}

trap {
    Write-UninstallerLog -Level 'ERROR' -Message $_.Exception.Message
    throw
}

Write-UninstallerLog -Level 'INFO' -Message 'UNINSTALL_STARTED'

function Test-IsCodexConnectionLauncher {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $text = [System.Text.Encoding]::Unicode.GetString($bytes)
        return $text.Contains('Codex Connection could not complete') -and $text.Contains('Start-CodexScopedProxy.ps1')
    }
    catch {
        return $false
    }
}

function Test-IsCodexConnectionShortcut {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($Path)
        $expectedLauncher = Join-Path $installRoot 'CodexConnectionLauncher.exe'
        return [string]::Equals($shortcut.TargetPath, $expectedLauncher, [System.StringComparison]::OrdinalIgnoreCase)
    }
    catch {
        return $false
    }
}

$zhStartName = 'Codex' + [char]0x542F + [char]0x52A8
$zhRestartName = 'Codex' + [char]0x91CD + [char]0x542F
$startMenuNames = @('Codex Connection.lnk', 'Start Codex.lnk', ($zhStartName + '.lnk'))
foreach ($name in $startMenuNames) {
    $startMenuShortcut = Join-Path $startMenuDirectory $name
    if (Test-IsCodexConnectionShortcut -Path $startMenuShortcut) {
        Remove-Item -LiteralPath $startMenuShortcut -Force
    }
}

$desktopNames = @('Start Codex.exe', 'Restart Codex.exe', ($zhStartName + '.exe'), ($zhRestartName + '.exe'))
foreach ($name in $desktopNames) {
    $desktopFile = Join-Path $desktopDirectory $name
    if (Test-IsCodexConnectionLauncher -Path $desktopFile) {
        Remove-Item -LiteralPath $desktopFile -Force
    }
}

if (Test-Path -LiteralPath $taskbarDirectory -PathType Container) {
    $shell = New-Object -ComObject WScript.Shell
    Get-ChildItem -LiteralPath $taskbarDirectory -Filter '*.lnk' -File -ErrorAction SilentlyContinue | ForEach-Object {
        $shortcut = $shell.CreateShortcut($_.FullName)
        if ($shortcut.TargetPath -like "*$expectedRoot*" -or $shortcut.Arguments -like "*$expectedRoot*") {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }
}

if (Test-Path -LiteralPath $installRoot -PathType Container) {
    $resolved = (Resolve-Path -LiteralPath $installRoot).Path.TrimEnd('\')
    if ($resolved -ne $expectedRoot) {
        throw "Refusing to remove an unexpected path: $resolved"
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}

Write-Output 'Codex Connection was removed. Codex, Clash, subscriptions, TUN, and system proxy settings were not changed.'
