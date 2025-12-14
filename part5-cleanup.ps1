# Part 5 - Cleanup Duplicate Files
# Run this anytime to clean up duplicate folders

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Cleanup: Removing Duplicate Files ===" -ForegroundColor Green

Set-Location $RootPath

# Remove duplicate src folder in root
if (Test-Path "$RootPath\src") {
    Write-Host "Removing duplicate src folder..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "$RootPath\src"
    Write-Host "Removed: $RootPath\src" -ForegroundColor Green
}

# Remove package-lock.json in root
if (Test-Path "$RootPath\package-lock.json") {
    Write-Host "Removing package-lock.json from root..." -ForegroundColor Yellow
    Remove-Item -Force "$RootPath\package-lock.json"
    Write-Host "Removed: $RootPath\package-lock.json" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Cleanup Complete! ===" -ForegroundColor Green
Write-Host "Duplicate files removed" -ForegroundColor Green