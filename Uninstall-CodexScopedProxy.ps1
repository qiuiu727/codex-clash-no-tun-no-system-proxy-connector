[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'CodexConnection'
$expectedRoot = [System.IO.Path]::GetFullPath($installRoot).TrimEnd('\')
$logDirectory = Join-Path $installRoot 'logs'
$logPath = Join-Path $logDirectory 'uninstaller.log'
$startMenuShortcut = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Codex Connection.lnk'
$taskbarDirectory = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'

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

if (Test-Path -LiteralPath $startMenuShortcut -PathType Leaf) {
    Remove-Item -LiteralPath $startMenuShortcut -Force
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
