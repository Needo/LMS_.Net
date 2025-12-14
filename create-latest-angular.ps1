# Create Latest Angular 19 Project
# This ensures we use the latest Angular version

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Creating Latest Angular 19 Project ===" -ForegroundColor Green

# Check Node version
$nodeVersion = node --version
Write-Host "Node.js version: $nodeVersion" -ForegroundColor Cyan

Set-Location $RootPath

# Remove old project
if (Test-Path "LMSUI") {
    Write-Host "Removing old Angular project..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "LMSUI"
}

Write-Host ""
Write-Host "Step 1: Updating Angular CLI to latest version..." -ForegroundColor Yellow
npm install -g @angular/cli@latest

Write-Host ""
Write-Host "Step 2: Verifying Angular CLI version..." -ForegroundColor Yellow
ng version

Write-Host ""
Write-Host "Step 3: Creating new Angular 19 project..." -ForegroundColor Yellow
Write-Host "(This will take 3-5 minutes)" -ForegroundColor Cyan
Write-Host ""

# Create project - Angular 17+ uses standalone by default, so we keep it
npx @angular/cli@latest new LMSUI --routing --style=scss --skip-git --ssr=false

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create project!" -ForegroundColor Red
    exit 1
}

Set-Location "$RootPath\LMSUI"

Write-Host ""
Write-Host "Step 4: Installing Angular Material..." -ForegroundColor Yellow
ng add @angular/material --skip-confirmation --theme=indigo-pink --typography=true --animations=true

Write-Host ""
Write-Host "Step 5: Creating project structure..." -ForegroundColor Yellow

# Create directories
New-Item -ItemType Directory -Force -Path "src/app/models" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/services" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/components/header" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/components/sidebar" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/components/viewer" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/components/admin" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/components/main-layout" | Out-Null

# =====================================
# CREATE MODELS
# =====================================
Write-Host "Creating models..." -ForegroundColor Cyan

$modelsTs = @'
export interface Course {
  id: number;
  name: string;
  path: string;
  createdDate: Date;
  items?: CourseItem[];
}

export interface CourseItem {
  id: number;
  courseId: number;
  parentId?: number;
  name: string;
  path: string;
  type: string;
  extension: string;
  size: number;
  children?: CourseItem[];
}
'@

Set-Content -Path "src/app/models/course.model.ts" -Value $modelsTs

# =====================================
# CREATE SERVICE
# =====================================
Write-Host "Creating service..." -ForegroundColor Cyan

$serviceTs = @'
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Course, CourseItem } from '../models/course.model';

@Injectable({
  providedIn: 'root'
})
export class CourseService {
  private apiUrl = 'http://localhost:5000/api';

  constructor(private http: HttpClient) {}

  getCourses(): Observable<Course[]> {
    return this.http.get<Course[]>(`${this.apiUrl}/courses`);
  }

  getCourseItems(courseId: number): Observable<CourseItem[]> {
    return this.http.get<CourseItem[]>(`${this.apiUrl}/courses/${courseId}/items`);
  }

  scanCourses(rootPath: string): Observable<any> {
    return this.http.post(`${this.apiUrl}/courses/scan`, { rootPath });
  }

  getFileUrl(path: string): string {
    return `${this.apiUrl}/files?path=${encodeURIComponent(path)}`;
  }
}
'@

Set-Content -Path "src/app/services/course.service.ts" -Value $serviceTs

# =====================================
# Generate components using Angular CLI
# =====================================
Write-Host "Generating components..." -ForegroundColor Cyan

ng generate component components/header --skip-tests
ng generate component components/sidebar --skip-tests
ng generate component components/viewer --skip-tests
ng generate component components/admin --skip-tests
ng generate component components/main-layout --skip-tests

# =====================================
# UPDATE COMPONENT FILES
# =====================================
Write-Host "Updating component templates..." -ForegroundColor Cyan

# Header
$headerHtml = @'
<mat-toolbar color="primary">
  <span>Learning Management System</span>
  <span class="spacer"></span>
  <button mat-button routerLink="/admin">
    <mat-icon>settings</mat-icon>
    Admin
  </button>
</mat-toolbar>
'@

$headerScss = '.spacer { flex: 1 1 auto; }'

Set-Content -Path "src/app/components/header/header.component.html" -Value $headerHtml -Force
Set-Content -Path "src/app/components/header/header.component.scss" -Value $headerScss -Force

# Sidebar
$sidebarTs = @'
import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { NestedTreeControl } from '@angular/cdk/tree';
import { MatTreeNestedDataSource } from '@angular/material/tree';
import { CourseService } from '../../services/course.service';
import { CourseItem } from '../../models/course.model';

@Component({
  selector: 'app-sidebar',
  templateUrl: './sidebar.component.html',
  styleUrls: ['./sidebar.component.scss']
})
export class SidebarComponent implements OnInit {
  @Output() fileSelected = new EventEmitter<CourseItem>();
  
  treeControl = new NestedTreeControl<CourseItem>(node => node.children);
  dataSource = new MatTreeNestedDataSource<CourseItem>();

  constructor(private courseService: CourseService) {}

  ngOnInit() {
    this.loadCourses();
  }

  loadCourses() {
    this.courseService.getCourses().subscribe({
      next: (courses) => {
        const items: CourseItem[] = [];
        let completed = 0;
        
        if (courses.length === 0) {
          this.dataSource.data = [];
          return;
        }
        
        courses.forEach(course => {
          this.courseService.getCourseItems(course.id).subscribe({
            next: (courseItems) => {
              const courseNode: CourseItem = {
                id: course.id,
                courseId: course.id,
                name: course.name,
                path: course.path,
                type: 'course',
                extension: '',
                size: 0,
                children: courseItems
              };
              items.push(courseNode);
              completed++;
              
              if (completed === courses.length) {
                this.dataSource.data = items;
              }
            }
          });
        });
      }
    });
  }

  hasChild = (_: number, node: CourseItem) => !!node.children && node.children.length > 0;

  toggleNode(node: CourseItem) {
    this.treeControl.toggle(node);
  }

  selectItem(node: CourseItem) {
    if (node.type !== 'folder' && node.type !== 'course') {
      this.fileSelected.emit(node);
    }
  }

  getIcon(type: string): string {
    switch(type) {
      case 'course': return 'school';
      case 'folder': return 'folder';
      case 'video': return 'video_library';
      case 'audio': return 'audiotrack';
      case 'document': return 'description';
      default: return 'insert_drive_file';
    }
  }
}
'@

$sidebarHtml = @'
<div class="sidebar">
  <mat-tree [dataSource]="dataSource" [treeControl]="treeControl">
    <mat-tree-node *matTreeNodeDef="let node" matTreeNodeToggle>
      <li class="mat-tree-node">
        <button mat-icon-button disabled></button>
        <span (click)="selectItem(node)" class="node-label">
          <mat-icon>{{ getIcon(node.type) }}</mat-icon>
          {{ node.name }}
        </span>
      </li>
    </mat-tree-node>

    <mat-nested-tree-node *matTreeNodeDef="let node; when: hasChild">
      <li>
        <div class="mat-tree-node">
          <button mat-icon-button matTreeNodeToggle>
            <mat-icon>
              {{ treeControl.isExpanded(node) ? 'expand_more' : 'chevron_right' }}
            </mat-icon>
          </button>
          <span (click)="toggleNode(node)" class="node-label">
            <mat-icon>{{ getIcon(node.type) }}</mat-icon>
            {{ node.name }}
          </span>
        </div>
        <ul [class.hidden]="!treeControl.isExpanded(node)">
          <ng-container matTreeNodeOutlet></ng-container>
        </ul>
      </li>
    </mat-nested-tree-node>
  </mat-tree>
</div>
'@

$sidebarScss = @'
.sidebar {
  width: 300px;
  background: #f5f5f5;
  overflow-y: auto;
  border-right: 1px solid #ddd;
  padding: 16px;
}

.mat-tree { background: transparent; }
.mat-tree-node {
  min-height: 40px;
  display: flex;
  align-items: center;
}

.node-label {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  &:hover { background: rgba(0,0,0,0.05); }
}

ul { padding-left: 20px; list-style: none; }
.hidden { display: none; }
'@

Set-Content -Path "src/app/components/sidebar/sidebar.component.ts" -Value $sidebarTs -Force
Set-Content -Path "src/app/components/sidebar/sidebar.component.html" -Value $sidebarHtml -Force
Set-Content -Path "src/app/components/sidebar/sidebar.component.scss" -Value $sidebarScss -Force

# Viewer
$viewerTs = @'
import { Component, Input, OnChanges } from '@angular/core';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { CourseItem } from '../../models/course.model';
import { CourseService } from '../../services/course.service';

@Component({
  selector: 'app-viewer',
  templateUrl: './viewer.component.html',
  styleUrls: ['./viewer.component.scss']
})
export class ViewerComponent implements OnChanges {
  @Input() selectedItem: CourseItem | null = null;
  fileUrl: string = '';

  constructor(
    private courseService: CourseService,
    private sanitizer: DomSanitizer
  ) {}

  ngOnChanges() {
    if (this.selectedItem) {
      this.fileUrl = this.courseService.getFileUrl(this.selectedItem.path);
    }
  }

  sanitizeUrl(url: string): SafeResourceUrl {
    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  }

  formatSize(bytes: number): string {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1048576) return (bytes / 1024).toFixed(2) + ' KB';
    return (bytes / 1048576).toFixed(2) + ' MB';
  }
}
'@

$viewerHtml = @'
<div class="viewer">
  @if (!selectedItem) {
    <div class="placeholder">
      <mat-icon>description</mat-icon>
      <p>Select a file to view</p>
    </div>
  }

  @if (selectedItem) {
    <div class="content">
      <h2>{{ selectedItem.name }}</h2>
      
      @if (selectedItem.type === 'video') {
        <video controls [src]="fileUrl" class="media"></video>
      }
      
      @if (selectedItem.type === 'audio') {
        <audio controls [src]="fileUrl" class="media"></audio>
      }
      
      @if (selectedItem.type === 'document' && selectedItem.extension === '.pdf') {
        <iframe [src]="sanitizeUrl(fileUrl)" class="document"></iframe>
      }
      
      @if (selectedItem.type === 'document' && selectedItem.extension !== '.pdf' || selectedItem.type === 'file') {
        <div class="file-info">
          <mat-icon>{{ selectedItem.type === 'document' ? 'description' : 'insert_drive_file' }}</mat-icon>
          <p>{{ selectedItem.name }}</p>
          <p>Size: {{ formatSize(selectedItem.size) }}</p>
          <a [href]="fileUrl" download mat-raised-button color="primary">
            <mat-icon>download</mat-icon>
            Download
          </a>
        </div>
      }
    </div>
  }
</div>
'@

$viewerScss = @'
.viewer {
  flex: 1;
  padding: 24px;
  overflow-y: auto;
  background: white;
}

.placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #999;
  mat-icon { font-size: 64px; width: 64px; height: 64px; }
}

.content h2 { margin-bottom: 24px; }
.media { width: 100%; max-width: 800px; border-radius: 8px; }
.document { width: 100%; height: 80vh; border: 1px solid #ddd; border-radius: 8px; }

.file-info {
  padding: 24px;
  background: #f5f5f5;
  border-radius: 8px;
  text-align: center;
  mat-icon { font-size: 64px; width: 64px; height: 64px; margin-bottom: 16px; }
  p { margin: 8px 0; }
  a { margin-top: 16px; }
}
'@

Set-Content -Path "src/app/components/viewer/viewer.component.ts" -Value $viewerTs -Force
Set-Content -Path "src/app/components/viewer/viewer.component.html" -Value $viewerHtml -Force
Set-Content -Path "src/app/components/viewer/viewer.component.scss" -Value $viewerScss -Force

# Admin
$adminTs = @'
import { Component } from '@angular/core';
import { CourseService } from '../../services/course.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-admin',
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.scss']
})
export class AdminComponent {
  rootPath: string = 'C:\\Courses';
  scanning: boolean = false;
  message: string = '';
  isError: boolean = false;

  constructor(
    private courseService: CourseService,
    private router: Router
  ) {}

  scanCourses() {
    this.scanning = true;
    this.message = '';
    
    this.courseService.scanCourses(this.rootPath).subscribe({
      next: (response) => {
        this.scanning = false;
        this.message = response.message || 'Scan completed successfully!';
        this.isError = false;
      },
      error: (error) => {
        this.scanning = false;
        this.message = 'Error: ' + (error.error || error.message);
        this.isError = true;
      }
    });
  }

  goBack() {
    this.router.navigate(['/']);
  }
}
'@

$adminHtml = @'
<div class="admin-panel">
  <button mat-icon-button (click)="goBack()" class="back-button">
    <mat-icon>arrow_back</mat-icon>
  </button>
  
  <h1>Admin Panel</h1>
  
  <mat-card>
    <mat-card-header>
      <mat-card-title>Course Scanner</mat-card-title>
    </mat-card-header>
    <mat-card-content>
      <p>Scan a directory to import courses. Each root folder will become a course.</p>
      
      <mat-form-field appearance="outline" class="full-width">
        <mat-label>Root Path</mat-label>
        <input matInput [(ngModel)]="rootPath" placeholder="C:\Courses">
        <mat-hint>Enter the path containing your course folders</mat-hint>
      </mat-form-field>
      
      <button mat-raised-button color="primary" (click)="scanCourses()" [disabled]="scanning">
        <mat-icon>search</mat-icon>
        {{ scanning ? 'Scanning...' : 'Scan Courses' }}
      </button>
      
      @if (message) {
        <div class="message" [class.error]="isError">
          <mat-icon>{{ isError ? 'error' : 'check_circle' }}</mat-icon>
          {{ message }}
        </div>
      }
    </mat-card-content>
  </mat-card>
</div>
'@

$adminScss = @'
.admin-panel {
  padding: 24px;
  max-width: 800px;
  margin: 0 auto;
}

.back-button { margin-bottom: 16px; }
mat-card { margin: 24px 0; }
.full-width { width: 100%; margin: 16px 0; }
button[mat-raised-button] { margin-top: 8px; }

.message {
  margin-top: 16px;
  padding: 12px;
  border-radius: 4px;
  background: #4caf50;
  color: white;
  display: flex;
  align-items: center;
  gap: 8px;
  &.error { background: #f44336; }
}
'@

Set-Content -Path "src/app/components/admin/admin.component.ts" -Value $adminTs -Force
Set-Content -Path "src/app/components/admin/admin.component.html" -Value $adminHtml -Force
Set-Content -Path "src/app/components/admin/admin.component.scss" -Value $adminScss -Force

# Main Layout
$mainLayoutTs = @'
import { Component } from '@angular/core';
import { CourseItem } from '../../models/course.model';

@Component({
  selector: 'app-main-layout',
  templateUrl: './main-layout.component.html',
  styleUrls: ['./main-layout.component.scss']
})
export class MainLayoutComponent {
  selectedItem: CourseItem | null = null;

  onFileSelected(item: CourseItem) {
    this.selectedItem = item;
  }
}
'@

$mainLayoutHtml = @'
<div class="app-container">
  <app-header></app-header>
  <div class="content-container">
    <app-sidebar (fileSelected)="onFileSelected($event)"></app-sidebar>
    <app-viewer [selectedItem]="selectedItem"></app-viewer>
  </div>
</div>
'@

$mainLayoutScss = @'
.app-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
}

.content-container {
  display: flex;
  flex: 1;
  overflow: hidden;
}
'@

Set-Content -Path "src/app/components/main-layout/main-layout.component.ts" -Value $mainLayoutTs -Force
Set-Content -Path "src/app/components/main-layout/main-layout.component.html" -Value $mainLayoutHtml -Force
Set-Content -Path "src/app/components/main-layout/main-layout.component.scss" -Value $mainLayoutScss -Force

# App Component
$appComponentHtml = '<router-outlet />'
Set-Content -Path "src/app/app.component.html" -Value $appComponentHtml -Force

# App Routes
$appRoutesTs = @'
import { Routes } from '@angular/router';
import { MainLayoutComponent } from './components/main-layout/main-layout.component';
import { AdminComponent } from './components/admin/admin.component';

export const routes: Routes = [
  { path: '', component: MainLayoutComponent },
  { path: 'admin', component: AdminComponent }
];
'@

Set-Content -Path "src/app/app.routes.ts" -Value $appRoutesTs -Force

# App Config
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
Write-Host "=== Angular 19 Project Created! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. cd LMSUI" -ForegroundColor White
Write-Host "2. ng serve --open" -ForegroundColor White
Write-Host ""
Write-Host "Or run the complete system:" -ForegroundColor Yellow
Write-Host "  C:\LMSSystem\run-all.bat" -ForegroundColor White
Write-Host ""