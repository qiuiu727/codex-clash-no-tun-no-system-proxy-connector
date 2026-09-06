[CmdletBinding()]
param(
    [switch]$GenerateRestartScript,
    [ValidateSet('en', 'zh')][string]$Language = 'en',
    [string]$DesktopDirectory
)

$ErrorActionPreference = 'Stop'
$installRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($DesktopDirectory)) {
    $desktopDirectory = [Environment]::GetFolderPath('DesktopDirectory')
}
else {
    $desktopDirectory = $DesktopDirectory
}
if ([string]::IsNullOrWhiteSpace($desktopDirectory)) {
    $desktopDirectory = Join-Path $env:USERPROFILE 'Desktop'
}

function Copy-PortableDesktopLauncher {
    param(
        [Parameter(Mandatory = $true)][string]$FileName,
        [Parameter(Mandatory = $true)][string]$LauncherPath
    )

    if (-not (Test-Path -LiteralPath $LauncherPath -PathType Leaf)) {
        throw "Installed launcher EXE was not found: $LauncherPath"
    }

    $desktopFile = Join-Path $desktopDirectory $FileName
    if (Test-Path -LiteralPath $desktopFile -PathType Leaf) {
        $existingHash = (Get-FileHash -LiteralPath $desktopFile -Algorithm SHA256).Hash
        $launcherHash = (Get-FileHash -LiteralPath $LauncherPath -Algorithm SHA256).Hash
        if ($existingHash -ne $launcherHash) {
            throw "Refusing to overwrite an unrelated Desktop file: $desktopFile"
        }
    }

    Copy-Item -LiteralPath $LauncherPath -Destination $desktopFile -Force
    Write-Output "Created portable Desktop EXE: $desktopFile"
}

New-Item -ItemType Directory -Path $desktopDirectory -Force | Out-Null
$launcherPath = Join-Path $installRoot 'CodexConnectionLauncher.exe'
$zhStartName = 'Codex' + [char]0x542F + [char]0x52A8 + '.exe'
$zhRestartName = 'Codex' + [char]0x91CD + [char]0x542F + '.exe'
$startName = if ($Language -eq 'zh') { $zhStartName } else { 'Start Codex.exe' }
$restartName = if ($Language -eq 'zh') { $zhRestartName } else { 'Restart Codex.exe' }
Copy-PortableDesktopLauncher -FileName $startName -LauncherPath $launcherPath

if ($GenerateRestartScript) {
    Copy-PortableDesktopLauncher -FileName $restartName -LauncherPath $launcherPath
}
