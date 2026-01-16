# Simple Backend Fix Script

Write-Host "Fixing LMS Backend..." -ForegroundColor Cyan
Write-Host ""

Set-Location "C:\LMSSystem\LMS.API"

# Step 1: Drop database
Write-Host "Step 1: Dropping old database..." -ForegroundColor Yellow
dotnet ef database drop --force
Write-Host ""

# Step 2: Delete migrations
Write-Host "Step 2: Removing old migrations..." -ForegroundColor Yellow
Remove-Item -Path "Migrations\*.cs" -Force -ErrorAction SilentlyContinue
Write-Host ""

# Step 3: Create new migration
Write-Host "Step 3: Creating new migration..." -ForegroundColor Yellow
dotnet ef migrations add InitialCreateV2
Write-Host ""

# Step 4: Update database
Write-Host "Step 4: Creating database..." -ForegroundColor Yellow
dotnet ef database update
Write-Host ""

Write-Host "Done! Database is ready." -ForegroundColor Green
Write-Host ""
Write-Host "Next: Run 'dotnet run' to start the API" -ForegroundColor Cyan
Write-Host ""
