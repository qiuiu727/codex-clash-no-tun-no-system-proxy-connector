[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'CodexConnection'
$expectedRoot = [System.IO.Path]::GetFullPath($installRoot).TrimEnd('\')
$startMenuShortcut = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Codex Connection.lnk'
$taskbarDirectory = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'

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
