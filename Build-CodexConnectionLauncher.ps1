[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot 'CodexConnectionLauncher.exe'
}
$compiler = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw 'The .NET Framework C# compiler was not found.'
}

$sourcePath = Join-Path $PSScriptRoot 'CodexConnectionLauncher.cs'
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Launcher source was not found: $sourcePath"
}

$iconPath = Join-Path $PSScriptRoot 'CodexConnection.ico'
$iconBuilderPath = Join-Path $PSScriptRoot 'New-CodexConnectionIcon.ps1'
if (-not (Test-Path -LiteralPath $iconBuilderPath -PathType Leaf)) {
    throw "Icon source was not found: $iconBuilderPath"
}
& $iconBuilderPath -OutputPath $iconPath
if (-not (Test-Path -LiteralPath $iconPath -PathType Leaf)) {
    throw 'The original Codex Connection icon could not be created.'
}

& $compiler /nologo /target:winexe /platform:anycpu /optimize+ "/win32icon:$iconPath" "/out:$OutputPath" /r:System.Windows.Forms.dll $sourcePath
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $OutputPath -PathType Leaf)) {
    throw 'The Codex Connection launcher EXE could not be built.'
}

Write-Output "Built $OutputPath"
