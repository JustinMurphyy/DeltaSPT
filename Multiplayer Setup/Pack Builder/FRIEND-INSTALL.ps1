param(
    [string]$TargetPath,
    [switch]$SkipFirewall
)

$ErrorActionPreference = 'Stop'
$packRoot = $PSScriptRoot
$logPath = Join-Path $packRoot 'INSTALL-LOG.txt'

function Write-Step([string]$Message) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Host $line -ForegroundColor Cyan
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
}

trap {
    $message = "ERROR: $($_.Exception.Message)"
    Write-Host $message -ForegroundColor Red
    try { Add-Content -LiteralPath $logPath -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message" -Encoding UTF8 } catch {}
    Read-Host 'Press Enter to close'
    exit 1
}

Write-Step 'Starting SPT Fika friend-pack installer.'

if (-not [Environment]::Is64BitOperatingSystem) { throw 'A 64-bit version of Windows is required.' }
if ([Environment]::OSVersion.Version.Major -lt 10) { throw 'Windows 10 or Windows 11 is required by this SPT/Fika build.' }
if ($PSVersionTable.PSVersion.Major -lt 5) { throw 'Windows PowerShell 5.1 or newer is required.' }

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $SkipFirewall -and -not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Step 'Requesting Windows administrator permission for the firewall rule.'
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $PSCommandPath + '"'))
    if ($TargetPath) { $arguments += @('-TargetPath', ('"' + $TargetPath + '"')) }
    Start-Process "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList $arguments
    exit
}

if (-not $TargetPath) {
    $candidate = Split-Path $packRoot -Parent
    if (Test-Path -LiteralPath (Join-Path $candidate 'EscapeFromTarkov.exe')) {
        $TargetPath = $candidate
    } else {
        Add-Type -AssemblyName System.Windows.Forms
        $picker = New-Object System.Windows.Forms.FolderBrowserDialog
        $picker.Description = 'Select your SPT 4.1.6 installation folder'
        $picker.ShowNewFolderButton = $false
        if ($picker.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { throw 'No SPT folder was selected.' }
        $TargetPath = $picker.SelectedPath
    }
}

$target = [IO.Path]::GetFullPath($TargetPath.Trim('"')).TrimEnd('\')
$gameExe = Join-Path $target 'EscapeFromTarkov.exe'
$serverExe = Join-Path $target 'SPT_Runtime\SPT.Server.exe'
$registry = Join-Path $target 'SPT_Runtime\user\sptRegistry\registry.json'
$payload = Join-Path $packRoot 'payload'
$manifestPath = Join-Path $packRoot 'PACK-MANIFEST.json'

if (-not (Test-Path -LiteralPath $gameExe) -or -not (Test-Path -LiteralPath $serverExe) -or -not (Test-Path -LiteralPath $registry)) { throw "Not a valid SPT installation: $target" }
if (-not (Test-Path -LiteralPath $payload) -or -not (Test-Path -LiteralPath $manifestPath)) { throw 'Pack payload or manifest is missing. Extract the complete ZIP before running the installer.' }
if (Get-Process -Name 'EscapeFromTarkov','SPT.Server','SPT.Launcher' -ErrorAction SilentlyContinue) { throw 'Close Escape From Tarkov, SPT.Server, and SPT.Launcher before installing.' }

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$installedSpt = (Get-Content -LiteralPath $registry -Raw | ConvertFrom-Json).SPT_Version
$eftVersion = (Get-Item -LiteralPath $gameExe).VersionInfo.FileVersion
if ($installedSpt -notmatch ([regex]::Escape($manifest.sptVersion))) { throw "Wrong SPT version. Required $($manifest.sptVersion); found $installedSpt" }
if ($eftVersion -ne $manifest.eftVersion) { throw "Wrong EFT version. Required $($manifest.eftVersion); found $eftVersion" }

Write-Step 'Verifying every file in the pack before installation.'
$packFailures = New-Object 'Collections.Generic.List[string]'
$payloadPrefix = ([IO.Path]::GetFullPath($payload).TrimEnd('\') + '\')
foreach ($file in $manifest.files) {
    $sourceFile = [IO.Path]::GetFullPath((Join-Path $payload ($file.path -replace '/', '\')))
    if (-not $sourceFile.StartsWith($payloadPrefix, [StringComparison]::OrdinalIgnoreCase)) { $packFailures.Add("UNSAFE PATH: $($file.path)") }
    elseif (-not (Test-Path -LiteralPath $sourceFile)) { $packFailures.Add("MISSING: $($file.path)") }
    elseif ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourceFile).Hash -ne $file.sha256) { $packFailures.Add("HASH MISMATCH: $($file.path)") }
}
if ($packFailures.Count) { throw "The pack is incomplete or damaged. Extract/download it again:`n$($packFailures -join "`n")" }

$payloadBytes = ($manifest.files | Measure-Object -Property bytes -Sum).Sum
$existingBytes = (Get-ChildItem -LiteralPath (Join-Path $target 'BepInEx') -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
$driveName = [IO.Path]::GetPathRoot($target).TrimEnd('\').TrimEnd(':')
$freeBytes = (Get-PSDrive -Name $driveName).Free
$requiredBytes = [long]$payloadBytes + [long]$existingBytes + 1GB
if ($freeBytes -lt $requiredBytes) { throw ('Not enough free disk space. Need approximately {0:N1} GB; available {1:N1} GB.' -f ($requiredBytes / 1GB), ($freeBytes / 1GB)) }

$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$backup = Join-Path $target "FriendPack-Backups\$stamp"
$changesStarted = $false
try {
    Write-Step "Backing up existing client mods to $backup"
    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    $changesStarted = $true
    $configSource = Join-Path $target 'BepInEx\config'
    if (Test-Path -LiteralPath $configSource) {
        $configBackup = Join-Path $backup 'BepInEx\config'
        New-Item -ItemType Directory -Force -Path (Split-Path $configBackup) | Out-Null
        Move-Item -LiteralPath $configSource -Destination $configBackup
    }
    $pluginDir = Join-Path $target 'BepInEx\plugins'
    $pluginBackup = Join-Path $backup 'BepInEx\plugins'
    New-Item -ItemType Directory -Force -Path $pluginBackup | Out-Null
    Get-ChildItem -LiteralPath $pluginDir -Force | Where-Object Name -ne 'spt' | ForEach-Object { Move-Item -LiteralPath $_.FullName -Destination $pluginBackup }
    Write-Step 'Copying the matched client mod set.'
    Copy-Item -LiteralPath (Join-Path $payload 'BepInEx') -Destination $target -Recurse -Force
    Write-Step 'Verifying installed files.'
    $installFailures = New-Object 'Collections.Generic.List[string]'
    foreach ($file in $manifest.files) {
        $installed = Join-Path $target ($file.path -replace '/', '\')
        if (-not (Test-Path -LiteralPath $installed)) { $installFailures.Add("MISSING: $($file.path)") }
        elseif ((Get-FileHash -Algorithm SHA256 -LiteralPath $installed).Hash -ne $file.sha256) { $installFailures.Add("HASH MISMATCH: $($file.path)") }
    }
    if ($installFailures.Count) { throw "Installation verification failed:`n$($installFailures -join "`n")" }

    if (-not $SkipFirewall) {
        Write-Step 'Creating the optional Fika raid-host firewall rule.'
        Get-NetFirewallRule -DisplayName 'Fika (Core) - UDP 25565' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
        New-NetFirewallRule -DisplayName 'Fika (Core) - UDP 25565' -Direction Inbound -Protocol UDP -LocalPort 25565 -Program $gameExe -Action Allow -Enabled True -Profile Any | Out-Null
    }
} catch {
    if ($changesStarted) {
        Write-Step 'Installation failed; restoring the previous client mods.'
        $newConfig = Join-Path $target 'BepInEx\config'
        if (Test-Path -LiteralPath $newConfig) { Remove-Item -LiteralPath $newConfig -Recurse -Force }
        Get-ChildItem -LiteralPath (Join-Path $target 'BepInEx\plugins') -Force | Where-Object Name -ne 'spt' | Remove-Item -Recurse -Force
        $oldConfig = Join-Path $backup 'BepInEx\config'
        if (Test-Path -LiteralPath $oldConfig) {
            New-Item -ItemType Directory -Force -Path (Split-Path $newConfig) | Out-Null
            Move-Item -LiteralPath $oldConfig -Destination $newConfig
        }
        $oldPlugins = Join-Path $backup 'BepInEx\plugins'
        if (Test-Path -LiteralPath $oldPlugins) { Get-ChildItem -LiteralPath $oldPlugins -Force | ForEach-Object { Move-Item -LiteralPath $_.FullName -Destination (Join-Path $target 'BepInEx\plugins') } }
    }
    throw
}

Write-Step 'SUCCESS: installation and SHA-256 verification completed.'
Write-Host ''
Write-Host 'Friend pack installed successfully.' -ForegroundColor Green
Write-Host "Backup of previous mods: $backup"
Write-Host 'Do not run SPT.Server on this PC. Open SPT Launcher and connect to the host.'
Read-Host 'Press Enter to close'

