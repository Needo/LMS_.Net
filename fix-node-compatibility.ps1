# Fix Node.js v24 Compatibility for Old Angular
# This adds legacy OpenSSL support

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Fixing Node.js v24 Compatibility ===" -ForegroundColor Green

Set-Location "$RootPath\LMSUI"

Write-Host "Adding NODE_OPTIONS to package.json scripts..." -ForegroundColor Yellow

# Read package.json
$packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json

# Update scripts to use legacy OpenSSL
$packageJson.scripts.start = "node --openssl-legacy-provider node_modules/@angular/cli/bin/ng serve"
$packageJson.scripts.build = "node --openssl-legacy-provider node_modules/@angular/cli/bin/ng build"

# Save package.json
$packageJson | ConvertTo-Json -Depth 10 | Set-Content "package.json"

Write-Host "Creating custom ng-serve.bat..." -ForegroundColor Yellow

# Create a custom serve script
$ngServeBat = @'
@echo off
set NODE_OPTIONS=--openssl-legacy-provider
ng serve --open --port 4200
'@

Set-Content -Path "ng-serve.bat" -Value $ngServeBat

Write-Host ""
Write-Host "=== Fix Applied! ===" -ForegroundColor Green
Write-Host ""
Write-Host "To run the UI, use ONE of these methods:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Method 1 (Easiest):" -ForegroundColor Cyan
Write-Host "  cd LMSUI" -ForegroundColor White
Write-Host "  .\ng-serve.bat" -ForegroundColor White
Write-Host ""
Write-Host "Method 2 (PowerShell):" -ForegroundColor Cyan
Write-Host "  cd LMSUI" -ForegroundColor White
Write-Host '  $env:NODE_OPTIONS="--openssl-legacy-provider"' -ForegroundColor White
Write-Host "  ng serve --open" -ForegroundColor White
Write-Host ""
Write-Host "Method 3 (CMD):" -ForegroundColor Cyan
Write-Host "  cd LMSUI" -ForegroundColor White
Write-Host "  set NODE_OPTIONS=--openssl-legacy-provider" -ForegroundColor White
Write-Host "  ng serve --open" -ForegroundColor White
Write-Host ""

# Also update the run-ui.bat in root
Set-Location $RootPath

$runUiScript = @'
@echo off
echo Starting LMS UI...
cd LMSUI
set NODE_OPTIONS=--openssl-legacy-provider
ng serve --open --port 4200
'@

Set-Content -Path "run-ui.bat" -Value $runUiScript

# Update run-all.bat
$runAllScript = @'
@echo off
echo ====================================
echo    LMS System Starting...
echo ====================================
echo.

echo [1/2] Starting API Server...
start "LMS API" cmd /k "cd LMS.API && dotnet run --urls=http://localhost:5000"

echo [2/2] Waiting for API to initialize...
timeout /t 8 /nobreak > nul

echo [2/2] Starting Angular UI...
start "LMS UI" cmd /k "cd LMSUI && set NODE_OPTIONS=--openssl-legacy-provider && ng serve --open --port 4200"

echo.
echo ====================================
echo    LMS System Started!
echo ====================================
echo.
echo API Server: http://localhost:5000
echo Swagger UI: http://localhost:5000/swagger
echo Frontend:   http://localhost:4200
echo.
echo Press any key to stop all services...
pause > nul

echo.
echo Stopping services...
taskkill /FI "WINDOWTITLE eq LMS API" /T /F 2>nul
taskkill /FI "WINDOWTITLE eq LMS UI" /T /F 2>nul
echo Services stopped.
'@

Set-Content -Path "run-all.bat" -Value $runAllScript

Write-Host "Updated run-ui.bat and run-all.bat with Node fix!" -ForegroundColor Green
Write-Host ""
Write-Host "NOTE: For best compatibility, consider downgrading to Node.js v20 LTS" -ForegroundColor Yellow
Write-Host ""