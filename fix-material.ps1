# Fix Angular Material Installation
# This manually completes the Material setup

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Fixing Angular Material Setup ===" -ForegroundColor Green

Set-Location "$RootPath\LMSUI"

Write-Host "Installing remaining Material dependencies..." -ForegroundColor Yellow
npm install @angular/cdk@21.0.3

Write-Host ""
Write-Host "Adding Material theme to styles..." -ForegroundColor Yellow

# Update styles.scss to include Material theme
$stylesScss = @'
/* You can add global styles to this file, and also import other style files */
@import '@angular/material/prebuilt-themes/indigo-pink.css';

html, body { 
    height: 100%; 
    margin: 0;
    font-family: Roboto, "Helvetica Neue", sans-serif;
}
'@

Set-Content -Path "src/styles.scss" -Value $stylesScss -Force

Write-Host "Adding Material icons..." -ForegroundColor Yellow

# Update index.html to include Material icons
$indexHtml = Get-Content "src/index.html" -Raw

if (-not $indexHtml.Contains("material-icons")) {
    $indexHtml = $indexHtml -replace '</head>', @'
  <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500&display=swap" rel="stylesheet">
  <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
</head>
'@
    Set-Content -Path "src/index.html" -Value $indexHtml -Force
}

Write-Host ""
Write-Host "Updating app.config.ts..." -ForegroundColor Yellow

# Make sure app.config has animations
$appConfigTs = @'
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { provideHttpClient } from '@angular/common/http';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideAnimationsAsync(),
    provideHttpClient()
  ]
};
'@

Set-Content -Path "src/app/app.config.ts" -Value $appConfigTs -Force

Write-Host ""
Write-Host "=== Material Setup Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Angular Material 21 is now installed and configured" -ForegroundColor Green
Write-Host ""
Write-Host "You can now continue with the main script or test with:" -ForegroundColor Yellow
Write-Host "  ng serve" -ForegroundColor White
Write-Host ""