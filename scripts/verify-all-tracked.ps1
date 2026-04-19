# Verifies every file under the repo (except .git) is tracked by git.
# Run from repo root: powershell -ExecutionPolicy Bypass -File .\scripts\verify-all-tracked.ps1
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $root

$missing = @()
Get-ChildItem -LiteralPath $root -Recurse -File -Force | ForEach-Object {
    $full = $_.FullName
    if ($full -match "\\.git\\") { return }
    $rel = $full.Substring($root.Path.Length).TrimStart("\", "/")
    $tracked = git ls-files -- "$rel" 2>$null
    if (-not $tracked) {
        $missing += $rel
    }
}

if ($missing.Count -gt 0) {
    Write-Host "UNTRACKED OR MISSING FROM INDEX:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host $_ }
    exit 1
}

Write-Host "OK: all $($((git ls-files | Measure-Object -Line).Lines)) tracked files; working tree matches index." -ForegroundColor Green
exit 0
