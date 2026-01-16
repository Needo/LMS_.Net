# Fix Backend Migration and Start System

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "LMS Backend Migration & Startup Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location "C:\LMSSystem\LMS.API"

# Step 1: Remove old migrations
Write-Host "Step 1: Cleaning old migrations..." -ForegroundColor Yellow
Remove-Item -Path "Migrations" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✓ Old migrations removed" -ForegroundColor Green
Write-Host ""

# Step 2: Drop and recreate database
Write-Host "Step 2: Recreating database..." -ForegroundColor Yellow
try {
    dotnet ef database drop --force
    Write-Host "✓ Old database dropped" -ForegroundColor Green
} catch {
    Write-Host "! No existing database to drop" -ForegroundColor Yellow
}
Write-Host ""

# Step 3: Create new migration with all tables
Write-Host "Step 3: Creating new migration..." -ForegroundColor Yellow
dotnet ef migrations add InitialCreateWithCategories
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Migration created successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to create migration" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}
Write-Host ""

# Step 4: Apply migration
Write-Host "Step 4: Applying migration to database..." -ForegroundColor Yellow
dotnet ef database update
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Database created successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to update database" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}
Write-Host ""

# Step 5: Seed initial admin user
Write-Host "Step 5: Creating initial admin user..." -ForegroundColor Yellow
$createUserSql = @"
USE LMSDB;

-- Check if user exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@lms.com')
BEGIN
    INSERT INTO Users (Email, PasswordHash, FirstName, LastName, Sex, Role, IsActive, CreatedDate)
    VALUES ('admin@lms.com', 'admin123', 'Admin', 'User', 'Male', 'Admin', 1, GETDATE());
    PRINT 'Admin user created';
END
ELSE
BEGIN
    PRINT 'Admin user already exists';
END

-- Check if student exists
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'student@lms.com')
BEGIN
    INSERT INTO Users (Email, PasswordHash, FirstName, LastName, Sex, Role, IsActive, CreatedDate)
    VALUES ('student@lms.com', 'student123', 'Test', 'Student', 'Male', 'Student', 1, GETDATE());
    PRINT 'Student user created';
END
ELSE
BEGIN
    PRINT 'Student user already exists';
END
"@

$createUserSql | Out-File -FilePath "seed-users.sql" -Encoding UTF8
sqlcmd -S "EMAAN-PC" -d "LMSDB" -i "seed-users.sql"
Remove-Item "seed-users.sql" -ErrorAction SilentlyContinue
Write-Host "✓ Initial users created" -ForegroundColor Green
Write-Host ""

Write-Host "==================================================" -ForegroundColor Green
Write-Host "Database setup complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Default Users Created:" -ForegroundColor Cyan
Write-Host "  Admin:   admin@lms.com / admin123" -ForegroundColor White
Write-Host "  Student: student@lms.com / student123" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Run: dotnet run" -ForegroundColor White
Write-Host "  2. Test API at: http://localhost:5000/swagger" -ForegroundColor White
Write-Host "  3. Start frontend: cd ..\LMSUI && ng serve" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to start the API server..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Start the API
Write-Host ""
Write-Host "Starting API server..." -ForegroundColor Cyan
dotnet run
