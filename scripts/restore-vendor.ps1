# Restores vendor/as3-crypto if the folder is missing (e.g. after manual delete or bad clone).
# Safe to run multiple times: skips if vendor/as3-crypto/src already exists.
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$target = Join-Path $root "vendor\as3-crypto"
$marker = Join-Path $target "src\com\hurlant\crypto\Crypto.as"

if (Test-Path $marker) {
    Write-Host "OK: vendor already present: $target" -ForegroundColor Green
    exit 0
}

Write-Host "Restoring vendor/as3-crypto (as3-crypto library)..." -ForegroundColor Yellow
$parent = Split-Path $target -Parent
if (-not (Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent | Out-Null
}

$tmp = Join-Path $env:TEMP ("as3-crypto-" + [guid]::NewGuid().ToString("N"))
git clone --depth 1 "https://github.com/timkurvers/as3-crypto.git" $tmp
if (-not (Test-Path $tmp)) {
    throw "clone failed"
}

if (Test-Path $target) {
    Remove-Item -Recurse -Force $target
}
Move-Item $tmp $target

# Match this repo's vendoring style: plain files, not a nested git repo
Remove-Item -Recurse -Force (Join-Path $target ".git") -ErrorAction SilentlyContinue

Write-Host "Done: $target" -ForegroundColor Green
exit 0
