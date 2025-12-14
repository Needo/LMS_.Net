# Part 3 - Create Database
# Run this after Part 2

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Part 3: Creating Database ===" -ForegroundColor Green
Set-Location "$RootPath\LMS.API"

# Check if Migrations folder exists
if (Test-Path "Migrations") {
    Write-Host "Database migrations already exist!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Run part4-create-samples.ps1" -ForegroundColor Cyan
    exit
}

Write-Host "Creating database migrations..." -ForegroundColor Yellow

try {
    dotnet ef migrations add InitialCreate
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Applying migrations to database..." -ForegroundColor Yellow
        dotnet ef database update
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "=== Part 3 Complete! ===" -ForegroundColor Green
            Write-Host "Database created successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next step: Run part4-create-samples.ps1" -ForegroundColor Cyan
        } else {
            Write-Host ""
            Write-Host "Database update failed!" -ForegroundColor Red
            Write-Host "Please check your SQL Server connection" -ForegroundColor Yellow
            Write-Host "Server: EMAAN-PC, User: sa" -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "Migration creation failed!" -ForegroundColor Red
    }
} catch {
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure:" -ForegroundColor Yellow
    Write-Host "1. SQL Server is running" -ForegroundColor White
    Write-Host "2. Connection string is correct in appsettings.json" -ForegroundColor White
    Write-Host "3. dotnet-ef tools are installed: dotnet tool install --global dotnet-ef" -ForegroundColor White
}