@echo off
echo ========================================
echo LMS System - One-Click Fix and Start
echo ========================================
echo.

cd /d C:\LMSSystem\LMS.API

echo [1/5] Dropping old database...
dotnet ef database drop --force
echo.

echo [2/5] Removing old migrations...
del /Q Migrations\*.cs 2>nul
echo.

echo [3/5] Creating new migration...
dotnet ef migrations add InitialCreateV2
echo.

echo [4/5] Creating database...
dotnet ef database update
echo.

echo [5/5] Starting API server...
echo.
echo ========================================
echo Backend is ready!
echo ========================================
echo.
echo API will start at: http://localhost:5000
echo Swagger UI at: http://localhost:5000/swagger
echo.
echo Press Ctrl+C to stop the server
echo.
dotnet run
