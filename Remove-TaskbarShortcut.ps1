[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$shortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Codex Scoped Proxy.lnk'
if (Test-Path -LiteralPath $shortcutPath -PathType Leaf) {
    Remove-Item -LiteralPath $shortcutPath -Force
    Write-Output "Removed $shortcutPath"
}
else {
    Write-Output 'The Start Menu shortcut was not present.'
}

Write-Output 'If you pinned it to the taskbar, unpin that taskbar item manually.'
