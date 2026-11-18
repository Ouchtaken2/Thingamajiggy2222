# Downloads the publicly served GameMaker HTML5 build of Frickbear's 3
# into the Game/ folder that gets bundled into the iOS app.
#
# Run from PowerShell:  .\Scripts\fetch-web-build.ps1
#
# IMPORTANT: This fetches third-party fan-game assets. Use for personal,
# non-commercial purposes only and keep the credits in CREDITS.md intact.

$ErrorActionPreference = "Stop"

$Base = "https://cdn.gachaplay.online/games/frickbears-3"
$Dest = Join-Path (Split-Path -Parent $PSScriptRoot) "Game"

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

Write-Host "==> Downloading index.html"
$indexPath = Join-Path $Dest "index.html"
Invoke-WebRequest -Uri "$Base/index.html" -OutFile $indexPath -UseBasicParsing
$html = Get-Content $indexPath -Raw

Write-Host "==> Resolving file list from manifestFiles()"
$manifest = [regex]::Match(
    $html,
    'function\s+manifestFiles\s*\(\s*\)\s*\{[\s\S]*?return\s*\[([\s\S]*?)\]\s*\.join'
)
$files = @()
if ($manifest.Success) {
    $files += [regex]::Matches($manifest.Groups[1].Value, '"([^"]+)"') |
              ForEach-Object { $_.Groups[1].Value }
}
$files += @(
    "index.html",
    "manifest.webmanifest",
    "icon-192.png",
    "runner.svg"
)
$files = $files | Where-Object { $_ } | Select-Object -Unique

if ($files.Count -eq 0) {
    throw "Could not parse file list - check the CDN build layout."
}

foreach ($name in $files) {
    $out = Join-Path $Dest $name
    if ((Test-Path $out) -and ((Get-Item $out).Length -gt 0)) {
        Write-Host "    skip    $name"
        continue
    }
    Write-Host "    fetch   $name"
    Invoke-WebRequest -Uri "$Base/$name" -OutFile $out -UseBasicParsing
}

$total = (Get-ChildItem $Dest -File | Measure-Object -Property Length -Sum).Sum
Write-Host ("==> Done. Game bundle size: {0:N1} MB" -f ($total / 1MB))
