# Part 2 - Install UI Dependencies (Fixed)
# Run this after Part 1

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Part 2: Installing Angular Dependencies ===" -ForegroundColor Green
Set-Location "$RootPath\LMSUI"

# Check if node_modules exists
if (Test-Path "node_modules") {
    Write-Host "Dependencies already installed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Run part3-create-database.ps1" -ForegroundColor Cyan
    exit
}

Write-Host "Fixing package.json dependency conflicts..." -ForegroundColor Yellow

# Read and fix package.json
$packageJsonPath = "package.json"
$packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json

# Update jasmine-core version to fix conflict
$packageJson.devDependencies.'jasmine-core' = "~3.8.0"

# Save updated package.json
$packageJson | ConvertTo-Json -Depth 10 | Set-Content $packageJsonPath

Write-Host "Installing npm packages with legacy peer deps..." -ForegroundColor Yellow
Write-Host "(This may take a few minutes)" -ForegroundColor Cyan
Write-Host ""

npm install --legacy-peer-deps

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== Part 2 Complete! ===" -ForegroundColor Green
    Write-Host "Angular dependencies installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Run part3-create-database.ps1" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Installation had errors" -ForegroundColor Red
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    # Try with force flag as backup
    npm install --force
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "=== Part 2 Complete! ===" -ForegroundColor Green
        Write-Host "Dependencies installed with --force flag" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Next step: Run part3-create-database.ps1" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "Both installation methods failed" -ForegroundColor Red
        Write-Host "Please check npm and Node.js installation" -ForegroundColor Yellow
    }
}