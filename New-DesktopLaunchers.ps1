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
        if ($existingHash -ne $launcherHash -and -not (Test-IsCodexConnectionLauncher -Path $desktopFile)) {
            throw "Refusing to overwrite an unrelated Desktop file: $desktopFile"
        }
    }

    Copy-Item -LiteralPath $LauncherPath -Destination $desktopFile -Force
    Write-Output "Created portable Desktop EXE: $desktopFile"
}

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

function Remove-GeneratedDesktopLauncher {
    param([Parameter(Mandatory = $true)][string]$FileName)

    $desktopFile = Join-Path $desktopDirectory $FileName
    if (-not (Test-Path -LiteralPath $desktopFile -PathType Leaf)) {
        return
    }
    if (-not (Test-IsCodexConnectionLauncher -Path $desktopFile)) {
        Write-Warning "Keeping an unrelated Desktop file: $desktopFile"
        return
    }
    Remove-Item -LiteralPath $desktopFile -Force
    Write-Output "Removed obsolete generated Desktop EXE: $desktopFile"
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
else {
    $otherRestartName = if ($Language -eq 'zh') { 'Restart Codex.exe' } else { $zhRestartName }
    Remove-GeneratedDesktopLauncher -FileName $restartName
    if ($otherRestartName -ne $restartName) {
        Remove-GeneratedDesktopLauncher -FileName $otherRestartName
    }
}
