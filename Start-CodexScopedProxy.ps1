[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'config.json'),
    [string]$LogDirectory,
    [switch]$DetectOnly
)

$ErrorActionPreference = 'Stop'
$logDirectory = if ([string]::IsNullOrWhiteSpace($LogDirectory)) {
    Join-Path (Split-Path -Parent $ConfigPath) 'logs'
}
else {
    $LogDirectory
}
$logPath = Join-Path $logDirectory 'launcher.log'

function Write-LauncherLog {
    param([Parameter(Mandatory = $true)][string]$Message)

    if (-not (Test-Path -LiteralPath $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }
    Add-Content -LiteralPath $logPath -Encoding UTF8 -Value ('{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message)
}

function ConvertTo-SafeLogMessage {
    param([Parameter(Mandatory = $true)][string]$Message)

    $safe = $Message
    $safe = $safe -replace '(?i)(vless|vmess|trojan|ss)://\S+', '<redacted-node-uri>'
    $safe = $safe -replace '(?i)(token|secret|password)=\S+', '$1=<redacted>'
    return $safe
}

function Test-LocalHttpProxy {
    param([Parameter(Mandatory = $true)][Uri]$ProxyUri)

    if ($ProxyUri.Scheme -notin @('http', 'https') -or [string]::IsNullOrWhiteSpace($ProxyUri.Host) -or $ProxyUri.Port -le 0) {
        return $false
    }

    try {
        $addresses = [System.Net.Dns]::GetHostAddresses($ProxyUri.Host)
        if (-not ($addresses | Where-Object { [System.Net.IPAddress]::IsLoopback($_) })) {
            return $false
        }

        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $connect = $client.BeginConnect($ProxyUri.Host, $ProxyUri.Port, $null, $null)
            if (-not $connect.AsyncWaitHandle.WaitOne(1500)) {
                return $false
            }
            $client.EndConnect($connect)
            $stream = $client.GetStream()
            $stream.ReadTimeout = 2000
            $request = [System.Text.Encoding]::ASCII.GetBytes("CONNECT chatgpt.com:443 HTTP/1.1`r`nHost: chatgpt.com:443`r`n`r`n")
            $stream.Write($request, 0, $request.Length)
            $buffer = New-Object byte[] 256
            $count = $stream.Read($buffer, 0, $buffer.Length)
            $firstLine = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $count).Split("`r`n")[0]
            return $firstLine -match '^HTTP/1\.[01] 2\d\d'
        }
        finally {
            $client.Dispose()
        }
    }
    catch {
        return $false
    }
}

function Get-ConfiguredProxyUri {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    try {
        $config = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([string]::IsNullOrWhiteSpace($config.proxyUrl) -or $config.proxyUrl -match '^<.+>$') {
            return $null
        }
        $proxyUri = [Uri]$config.proxyUrl
        if (Test-LocalHttpProxy -ProxyUri $proxyUri) {
            return $proxyUri
        }
        return $null
    }
    catch {
        return $null
    }
}

function Find-LocalHttpProxy {
    $knownCoreProcessPattern = 'clash|mihomo|sing-box|v2ray|xray|nekoray|hiddify'
    $candidates = @()

    foreach ($connection in (Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue)) {
        $address = $connection.LocalAddress
        if ($address -notin @('127.0.0.1', '::1')) {
            continue
        }

        try {
            $process = Get-Process -Id $connection.OwningProcess -ErrorAction Stop
            if ($process.ProcessName -notmatch $knownCoreProcessPattern) {
                continue
            }
            $host = if ($address -eq '::1') { '[::1]' } else { $address }
            $candidates += [Uri]("http://$host`:$($connection.LocalPort)")
        }
        catch {}
    }

    foreach ($candidate in ($candidates | Sort-Object AbsoluteUri -Unique)) {
        if (Test-LocalHttpProxy -ProxyUri $candidate) {
            return $candidate
        }
    }
    return $null
}

function Save-ProxyUri {
    param(
        [Parameter(Mandatory = $true)][Uri]$ProxyUri,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $content = [pscustomobject]@{ proxyUrl = $ProxyUri.AbsoluteUri.TrimEnd('/') } | ConvertTo-Json
    [System.IO.File]::WriteAllText($Path, $content + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
}

function Resolve-ProxyUri {
    param([Parameter(Mandatory = $true)][string]$Path)

    $configured = Get-ConfiguredProxyUri -Path $Path
    if ($configured) {
        return $configured
    }

    $detected = Find-LocalHttpProxy
    if ($detected) {
        Save-ProxyUri -ProxyUri $detected -Path $Path
        return $detected
    }

    throw 'No working local HTTP proxy was detected. Start your local proxy core first; this launcher does not install or configure subscriptions.'
}

function Show-ExistingCodexWindow {
    $running = @(Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue)
    if ($running.Count -eq 0) {
        return $false
    }

    Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class CodexWindowApi {
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr handle, int command);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr handle);
}
'@ -ErrorAction SilentlyContinue

    foreach ($process in $running) {
        if ($process.MainWindowHandle -ne 0) {
            [CodexWindowApi]::ShowWindow($process.MainWindowHandle, 9) | Out-Null
            [CodexWindowApi]::SetForegroundWindow($process.MainWindowHandle) | Out-Null
            Write-LauncherLog "FOCUSED pid=$($process.Id)"
            return $true
        }
    }

    Write-LauncherLog 'ALREADY_STARTING ChatGPT process exists without a main window'
    return $true
}

try {
    if ($DetectOnly) {
        $proxyUri = Resolve-ProxyUri -Path $ConfigPath
        Write-LauncherLog 'DETECTED local HTTP proxy'
        exit 0
    }

    if (Show-ExistingCodexWindow) {
        exit 0
    }

    $proxyUri = Resolve-ProxyUri -Path $ConfigPath

    $package = Get-AppxPackage -Name 'OpenAI.Codex' -ErrorAction Stop |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if (-not $package) {
        throw 'Microsoft Store Codex was not found.'
    }

    $appPath = Join-Path $package.InstallLocation 'app\ChatGPT.exe'
    if (-not (Test-Path -LiteralPath $appPath -PathType Leaf)) {
        throw "Codex executable was not found: $appPath"
    }

    $proxyUrl = $proxyUri.AbsoluteUri.TrimEnd('/')
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $appPath
    $startInfo.WorkingDirectory = Split-Path -Parent $appPath
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.Arguments = "--proxy-server=$($proxyUri.Host):$($proxyUri.Port) --proxy-bypass-list=<local>"
    $startInfo.EnvironmentVariables['HTTP_PROXY'] = $proxyUrl
    $startInfo.EnvironmentVariables['HTTPS_PROXY'] = $proxyUrl
    $startInfo.EnvironmentVariables['http_proxy'] = $proxyUrl
    $startInfo.EnvironmentVariables['https_proxy'] = $proxyUrl
    $startInfo.EnvironmentVariables['NO_PROXY'] = 'localhost,127.0.0.1,::1'
    $startInfo.EnvironmentVariables['no_proxy'] = 'localhost,127.0.0.1,::1'
    $startInfo.EnvironmentVariables.Remove('ALL_PROXY')
    $startInfo.EnvironmentVariables.Remove('all_proxy')

    $process = [System.Diagnostics.Process]::Start($startInfo)
    Write-LauncherLog "STARTED pid=$($process.Id)"
    exit 0
}
catch {
    Write-LauncherLog "FAILED error=$(ConvertTo-SafeLogMessage -Message $_.Exception.Message)"
    exit 1
}
