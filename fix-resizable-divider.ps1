# Fix Resizable Divider - Instant Response

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Fixing Resizable Divider ===" -ForegroundColor Green

Set-Location "$RootPath\LMSUI\src\app\components"

# Update main-layout component
Write-Host "Updating main-layout component..." -ForegroundColor Yellow

$mainLayoutTs = @'
import { Component, NgZone } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../header/header.component';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { ViewerComponent } from '../viewer/viewer.component';
import { CourseItem } from '../../models/course.model';

@Component({
  selector: 'app-main-layout',
  standalone: true,
  imports: [CommonModule, HeaderComponent, SidebarComponent, ViewerComponent],
  template: `
    <div class="app-container" [class.resizing]="isResizing">
      <app-header></app-header>
      <div class="content-container">
        <div class="sidebar-wrapper" [style.width.px]="sidebarWidth">
          <app-sidebar (fileSelected)="onFileSelected($event)"></app-sidebar>
        </div>
        <div class="divider" 
             (mousedown)="startResize($event)"
             [class.dragging]="isResizing">
        </div>
        <div class="viewer-wrapper">
          <app-viewer [selectedItem]="selectedItem"></app-viewer>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .app-container {
      display: flex;
      flex-direction: column;
      height: 100vh;
      overflow: hidden;
    }

    .content-container {
      display: flex;
      flex: 1;
      overflow: hidden;
      min-height: 0;
      position: relative;
    }

    .sidebar-wrapper {
      height: 100%;
      overflow: hidden;
      background: #f5f5f5;
      border-right: 1px solid #ddd;
      flex-shrink: 0;
      min-width: 200px;
      max-width: 600px;
    }

    .sidebar-wrapper app-sidebar {
      display: block;
      height: 100%;
      width: 100%;
    }

    .divider {
      width: 6px;
      background: #ccc;
      cursor: col-resize;
      flex-shrink: 0;
      position: relative;
      z-index: 10;
      transition: background 0.2s;
    }

    .divider:hover {
      background: #999;
    }

    .divider.dragging {
      background: #666;
    }

    .divider::before {
      content: '';
      position: absolute;
      left: 2px;
      top: 50%;
      transform: translateY(-50%);
      width: 2px;
      height: 40px;
      background: rgba(255, 255, 255, 0.5);
      border-radius: 1px;
    }

    .viewer-wrapper {
      flex: 1;
      display: flex;
      flex-direction: column;
      height: 100%;
      overflow: hidden;
      min-width: 0;
    }

    .viewer-wrapper app-viewer {
      flex: 1;
      display: flex;
      flex-direction: column;
      width: 100%;
      height: 100%;
    }

    .app-container.resizing {
      user-select: none;
      cursor: col-resize;
    }

    .app-container.resizing * {
      cursor: col-resize !important;
    }
  `]
})
export class MainLayoutComponent {
  selectedItem: CourseItem | null = null;
  sidebarWidth = 300;
  isResizing = false;

  constructor(private ngZone: NgZone) {}

  onFileSelected(item: CourseItem) {
    this.selectedItem = item;
  }

  startResize(event: MouseEvent) {
    event.preventDefault();
    this.isResizing = true;
    
    const startX = event.clientX;
    const startWidth = this.sidebarWidth;

    this.ngZone.runOutsideAngular(() => {
      const onMouseMove = (moveEvent: MouseEvent) => {
        const delta = moveEvent.clientX - startX;
        const newWidth = startWidth + delta;
        const constrainedWidth = Math.min(600, Math.max(200, newWidth));
        
        const sidebarElement = document.querySelector('.sidebar-wrapper') as HTMLElement;
        if (sidebarElement) {
          sidebarElement.style.width = `${constrainedWidth}px`;
        }
        
        this.sidebarWidth = constrainedWidth;
      };

      const onMouseUp = () => {
        this.ngZone.run(() => {
          this.isResizing = false;
        });

        document.removeEventListener('mousemove', onMouseMove);
        document.removeEventListener('mouseup', onMouseUp);
      };

      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup', onMouseUp);
    });
  }
}
'@

Set-Content -Path "main-layout/main-layout.component.ts" -Value $mainLayoutTs -Force

# Update sidebar to fill available width
Write-Host "Updating sidebar to auto-expand..." -ForegroundColor Yellow

$sidebarContent = Get-Content "sidebar/sidebar.component.ts" -Raw

# Replace the width in sidebar styles
$sidebarContent = $sidebarContent -replace 'width: 300px;', 'width: 100%;'
$sidebarContent = $sidebarContent -replace '\.sidebar \{[^}]+\}', @'
.sidebar { 
      width: 100%;
      height: 100%;
      background: #f5f5f5; 
      overflow-y: auto; 
      padding: 16px; 
      display: flex;
      flex-direction: column;
      box-sizing: border-box;
    }
'@

Set-Content -Path "sidebar/sidebar.component.ts" -Value $sidebarContent -Force

Write-Host ""
Write-Host "=== Fix Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Changes made:" -ForegroundColor Cyan
Write-Host "  ✓ Divider now responds instantly (uses NgZone for performance)" -ForegroundColor White
Write-Host "  ✓ Sidebar auto-expands to fill available width" -ForegroundColor White
Write-Host "  ✓ Smooth drag experience with visual feedback" -ForegroundColor White
Write-Host "  ✓ Min width: 200px, Max width: 600px" -ForegroundColor White
Write-Host ""
Write-Host "Restart Angular to see changes:" -ForegroundColor Yellow
Write-Host "  cd LMSUI && ng serve" -ForegroundColor Gray
Write-Host ""