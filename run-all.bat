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
