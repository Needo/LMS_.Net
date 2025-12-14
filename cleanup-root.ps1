# Cleanup duplicate files/folders at root

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Cleaning up root duplicates ===" -ForegroundColor Green

Set-Location $RootPath

$cleaned = $false

if (Test-Path "src") {
    Write-Host "Removing duplicate src folder..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "src"
    Write-Host "  Removed: src/" -ForegroundColor Green
    $cleaned = $true
}

if (Test-Path "package-lock.json") {
    Write-Host "Removing package-lock.json..." -ForegroundColor Yellow
    Remove-Item -Force "package-lock.json"
    Write-Host "  Removed: package-lock.json" -ForegroundColor Green
    $cleaned = $true
}

if (-not $cleaned) {
    Write-Host "No duplicate files found - already clean!" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Cleanup complete! ===" -ForegroundColor Green