[CmdletBinding()]
param(
    [switch]$GenerateRestartScript,
    [ValidateSet('en', 'zh')][string]$Language = 'en'
)

$ErrorActionPreference = 'Stop'
$installRoot = Join-Path $env:LOCALAPPDATA 'CodexConnection'
$sourceRoot = $PSScriptRoot
$logDirectory = Join-Path $installRoot 'logs'
$logPath = Join-Path $logDirectory 'installer.log'

function Write-InstallerLog {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }
    Add-Content -LiteralPath $logPath -Encoding UTF8 -Value ('{0} [INSTALLER] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message)
}

trap {
    Write-InstallerLog -Level 'ERROR' -Message $_.Exception.Message
    throw
}

Write-InstallerLog -Level 'INFO' -Message 'INSTALL_STARTED'
$filesToInstall = @(
    'Start-CodexScopedProxy.ps1',
    'CodexConnectionLauncher.exe',
    'New-TaskbarShortcut.ps1',
    'New-DesktopLaunchers.ps1',
    'Uninstall-CodexScopedProxy.ps1',
    'Start-CodexConnection.cmd'
)

if ($GenerateRestartScript) {
    $filesToInstall += @(
        'Restart-CodexConnection.ps1',
        'Restart-CodexConnection.cmd'
    )
}

foreach ($file in $filesToInstall) {
    if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $file) -PathType Leaf)) {
        throw "Required installer file is missing: $file"
    }
}

$tempRoot = Join-Path $env:TEMP ('CodexConnection-' + [Guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    $tempConfigPath = Join-Path $tempRoot 'config.json'
    & (Join-Path $sourceRoot 'Start-CodexScopedProxy.ps1') -DetectOnly -ConfigPath $tempConfigPath
    if (-not $?) {
        throw 'Installation stopped because no working local HTTP proxy was detected. Start your local proxy core first. No system proxy, TUN, or subscription was changed.'
    }
    Write-InstallerLog -Level 'INFO' -Message 'LOCAL_PROXY_DETECTED'

    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    foreach ($file in $filesToInstall) {
        Copy-Item -LiteralPath (Join-Path $sourceRoot $file) -Destination (Join-Path $installRoot $file) -Force
    }
    if (-not $GenerateRestartScript) {
        foreach ($file in @('Restart-CodexConnection.ps1', 'Restart-CodexConnection.cmd')) {
            $optionalFile = Join-Path $installRoot $file
            if (Test-Path -LiteralPath $optionalFile -PathType Leaf) {
                Remove-Item -LiteralPath $optionalFile -Force
            }
        }
    }
    Copy-Item -LiteralPath $tempConfigPath -Destination (Join-Path $installRoot 'config.json') -Force

    & (Join-Path $installRoot 'New-TaskbarShortcut.ps1') -Language $Language
    if (-not $?) {
        throw 'The launcher was installed, but the Start Menu shortcut could not be created.'
    }

    & (Join-Path $installRoot 'New-DesktopLaunchers.ps1') -GenerateRestartScript:$GenerateRestartScript -Language $Language
    if (-not $?) {
        throw 'The launcher was installed, but the Desktop launcher could not be created.'
    }
}
finally {
    if (Test-Path -LiteralPath $tempRoot -PathType Container) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

Write-Output "Installed to $installRoot"
Write-InstallerLog -Level 'INFO' -Message 'INSTALL_COMPLETED'
Write-Output 'The local proxy endpoint was auto-detected and saved only in the local installation directory.'
Write-Output 'A portable Codex launcher EXE with the original code-and-connection icon was created on the Desktop. You can move it anywhere; it always uses the local installation directory.'
Write-Output 'A matching Start Menu shortcut was created. Right-click it and choose Pin to taskbar.'
if ($GenerateRestartScript) {
    Write-Output 'A portable restart launcher EXE was also created on the Desktop.'
}
