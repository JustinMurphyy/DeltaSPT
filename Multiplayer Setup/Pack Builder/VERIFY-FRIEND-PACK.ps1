$ErrorActionPreference = 'Stop'
$packRoot = $PSScriptRoot
$manifest = Get-Content -LiteralPath (Join-Path $packRoot 'PACK-MANIFEST.json') -Raw | ConvertFrom-Json
$bad = [Collections.Generic.List[string]]::new()
foreach ($file in $manifest.files) {
    $path = Join-Path (Join-Path $packRoot 'payload') ($file.path -replace '/', '\')
    if (-not (Test-Path -LiteralPath $path)) {
        $bad.Add("MISSING: $($file.path)")
    } elseif ((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash -ne $file.sha256) {
        $bad.Add("HASH MISMATCH: $($file.path)")
    }
}
if ($bad.Count) { throw ($bad -join "`n") }
Write-Host "Pack $($manifest.packVersion) is complete: $($manifest.files.Count) files verified." -ForegroundColor Green

