# Fix Routing Issue
# Make sure routes are properly configured

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Fixing Routing ===" -ForegroundColor Green

Set-Location "$RootPath\LMSUI\src\app"

# Check if app.config.ts exists, if not create it
if (-not (Test-Path "app.config.ts")) {
    Write-Host "Creating app.config.ts..." -ForegroundColor Yellow
    
    $appConfig = @'
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
    Set-Content -Path "app.config.ts" -Value $appConfig
}

# Verify routes file
Write-Host "Verifying app.routes.ts..." -ForegroundColor Yellow

$routes = @'
import { Routes } from '@angular/router';
import { MainLayoutComponent } from './components/main-layout/main-layout.component';
import { AdminComponent } from './components/admin/admin.component';

export const routes: Routes = [
  { path: '', component: MainLayoutComponent },
  { path: 'admin', component: AdminComponent },
  { path: '**', redirectTo: '' }
];
'@
Set-Content -Path "app.routes.ts" -Value $routes -Force

# Verify app.component.ts
Write-Host "Verifying app.component.ts..." -ForegroundColor Yellow

$appComponent = @'
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  template: '<router-outlet />',
  styles: []
})
export class AppComponent {
  title = 'LMS System';
}
'@
Set-Content -Path "app.component.ts" -Value $appComponent -Force

Write-Host ""
Write-Host "=== Fix Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Stop the server (Ctrl+C) and restart:" -ForegroundColor Yellow
Write-Host "  ng serve" -ForegroundColor White
Write-Host ""
Write-Host "Then open: http://localhost:4200" -ForegroundColor Cyan
Write-Host ""