param([string]$OutputRoot)

$ErrorActionPreference = 'Stop'
$templateRoot = $PSScriptRoot
$source = $PSScriptRoot
while ($source -and -not (Test-Path -LiteralPath (Join-Path $source 'EscapeFromTarkov.exe'))) {
    $parent = Split-Path $source -Parent
    if ($parent -eq $source) { break }
    $source = $parent
}
if (-not $OutputRoot) { $OutputRoot = Split-Path $templateRoot -Parent }
$packName = 'SPT-Fika-CLIENT-Pack-4.1.6-native-ai-client.5'
$pack = Join-Path $OutputRoot $packName
if (Test-Path -LiteralPath $pack) { throw "Output already exists: $pack" }

$payload = Join-Path $pack 'payload'
New-Item -ItemType Directory -Force -Path (Join-Path $payload 'BepInEx\plugins') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $payload 'BepInEx\config') | Out-Null
$payloadFull = (Resolve-Path -LiteralPath $payload).Path

Get-ChildItem -LiteralPath (Join-Path $source 'BepInEx\plugins') -Force | Where-Object Name -ne 'spt' | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $payload 'BepInEx\plugins') -Recurse -Force
}
Copy-Item -Path (Join-Path $source 'BepInEx\config\*') -Destination (Join-Path $payload 'BepInEx\config') -Recurse -Force

foreach ($name in @('FRIEND-INSTALL.ps1','INSTALL-FRIEND-PACK.cmd','VERIFY-FRIEND-PACK.ps1','FRIEND-GUIDE.html','OPEN-GUIDE.cmd','FRIEND-README.txt','FRIEND-QUICK-START.png','FRIEND-QUICK-START-REMOTE.png')) {
    Copy-Item -LiteralPath (Join-Path $templateRoot $name) -Destination $pack
}

@'
SPT/FIKA REMOTE CONNECTION
==========================

Launcher server address:
https://HOST_ADDRESS:6969

Only the host runs SPT.Server. Friends run SPT Launcher and connect to the
address supplied privately by the host. Do not commit a public IP, VPN address,
password, certificate, or API key to the client-pack repository.
'@ | Set-Content -LiteralPath (Join-Path $pack 'REMOTE-CONNECTION-INFO.txt') -Encoding UTF8

$files = Get-ChildItem -LiteralPath $payloadFull -Recurse -File | ForEach-Object {
    [pscustomobject]@{
        path = $_.FullName.Substring($payloadFull.Length + 1).Replace('\','/')
        bytes = $_.Length
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
}
$manifest = [ordered]@{
    packVersion = '2026.10.11-native-ai-client.5'
    createdUtc = [DateTime]::UtcNow.ToString('o')
    sptVersion = '4.1.6'
    eftVersion = '0.16.9.40743'
    fikaClient = '2.4.4'
    fikaServer = '2.4.2'
    fileCount = @($files).Count
    files = @($files)
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $pack 'PACK-MANIFEST.json') -Encoding UTF8
Write-Host "Built $pack"
