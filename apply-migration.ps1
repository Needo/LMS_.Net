# Run this script to create and apply the database migration

Write-Host "Creating database migration..." -ForegroundColor Cyan

Set-Location "C:\LMSSystem\LMS.API"

# Remove old migrations if needed (optional - uncomment if you want fresh start)
# Remove-Item -Path "Migrations" -Recurse -Force -ErrorAction SilentlyContinue

# Create new migration
dotnet ef migrations add CategoryAndSubscriptionFeatures

if ($LASTEXITCODE -eq 0) {
    Write-Host "Migration created successfully!" -ForegroundColor Green
    
    # Apply migration to database
    Write-Host "Applying migration to database..." -ForegroundColor Cyan
    dotnet ef database update
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Database updated successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to update database!" -ForegroundColor Red
    }
} else {
    Write-Host "Failed to create migration!" -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
