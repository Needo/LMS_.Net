# Recreate Angular UI with Latest Angular (v19)
# Compatible with Node v24

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Recreating Angular UI with Latest Angular ===" -ForegroundColor Green

Set-Location $RootPath

# Remove old Angular project
if (Test-Path "LMSUI") {
    Write-Host "Removing old Angular project..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "LMSUI"
}

Write-Host "Creating new Angular project..." -ForegroundColor Yellow
Write-Host "(This will take a few minutes)" -ForegroundColor Cyan
Write-Host ""

# Create new Angular project - use package-manager to avoid npm install during creation
ng new LMSUI --routing --style=scss --skip-git --package-manager=npm --skip-install

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create Angular project!" -ForegroundColor Red
    exit 1
}

Set-Location "$RootPath\LMSUI"

Write-Host ""
Write-Host "Fixing package.json dependencies..." -ForegroundColor Yellow

# Read package.json
$packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json

# Fix the jasmine-core version conflict
if ($packageJson.devDependencies.'jasmine-core') {
    $packageJson.devDependencies.'jasmine-core' = "~3.10.0"
}

# Save fixed package.json
$packageJson | ConvertTo-Json -Depth 10 | Set-Content "package.json"

Write-Host "Installing dependencies with --legacy-peer-deps..." -ForegroundColor Yellow
npm install --legacy-peer-deps

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "npm install failed, trying with --force..." -ForegroundColor Yellow
    npm install --force
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Installation failed!" -ForegroundColor Red
        exit 1
    }
}

Set-Location "$RootPath\LMSUI"

Write-Host ""
Write-Host "Installing Angular Material..." -ForegroundColor Yellow
ng add @angular/material --skip-confirmation --theme=indigo-pink --typography=true --animations=true

Write-Host ""
Write-Host "Creating project structure..." -ForegroundColor Yellow

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
# HEADER COMPONENT
# =====================================
Write-Host "Creating header component..." -ForegroundColor Cyan

$headerTs = @'
import { Component } from '@angular/core';

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.scss']
})
export class HeaderComponent {}
'@

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

$headerScss = @'
.spacer {
  flex: 1 1 auto;
}
'@

Set-Content -Path "src/app/components/header/header.component.ts" -Value $headerTs
Set-Content -Path "src/app/components/header/header.component.html" -Value $headerHtml
Set-Content -Path "src/app/components/header/header.component.scss" -Value $headerScss

# =====================================
# SIDEBAR COMPONENT
# =====================================
Write-Host "Creating sidebar component..." -ForegroundColor Cyan

$sidebarTs = @'
import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { NestedTreeControl } from '@angular/cdk/tree';
import { MatTreeNestedDataSource } from '@angular/material/tree';
import { CourseService } from '../../services/course.service';
import { Course, CourseItem } from '../../models/course.model';

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

.mat-tree {
  background: transparent;
}

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
  
  &:hover {
    background: rgba(0,0,0,0.05);
  }
}

ul {
  padding-left: 20px;
  list-style: none;
}

.hidden {
  display: none;
}
'@

Set-Content -Path "src/app/components/sidebar/sidebar.component.ts" -Value $sidebarTs
Set-Content -Path "src/app/components/sidebar/sidebar.component.html" -Value $sidebarHtml
Set-Content -Path "src/app/components/sidebar/sidebar.component.scss" -Value $sidebarScss

# =====================================
# VIEWER COMPONENT
# =====================================
Write-Host "Creating viewer component..." -ForegroundColor Cyan

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
  <div *ngIf="!selectedItem" class="placeholder">
    <mat-icon>description</mat-icon>
    <p>Select a file to view</p>
  </div>

  <div *ngIf="selectedItem" class="content">
    <h2>{{ selectedItem.name }}</h2>
    
    <video *ngIf="selectedItem.type === 'video'" controls [src]="fileUrl" class="media"></video>
    
    <audio *ngIf="selectedItem.type === 'audio'" controls [src]="fileUrl" class="media"></audio>
    
    <iframe *ngIf="selectedItem.type === 'document' && selectedItem.extension === '.pdf'" 
            [src]="sanitizeUrl(fileUrl)" class="document"></iframe>
    
    <div *ngIf="selectedItem.type === 'document' && selectedItem.extension !== '.pdf'" class="file-info">
      <mat-icon>description</mat-icon>
      <p>{{ selectedItem.name }}</p>
      <p>Size: {{ formatSize(selectedItem.size) }}</p>
      <a [href]="fileUrl" download mat-raised-button color="primary">
        <mat-icon>download</mat-icon>
        Download
      </a>
    </div>
    
    <div *ngIf="selectedItem.type === 'file'" class="file-info">
      <mat-icon>insert_drive_file</mat-icon>
      <p>{{ selectedItem.name }}</p>
      <p>Size: {{ formatSize(selectedItem.size) }}</p>
      <a [href]="fileUrl" download mat-raised-button color="primary">
        <mat-icon>download</mat-icon>
        Download
      </a>
    </div>
  </div>
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
  
  mat-icon {
    font-size: 64px;
    width: 64px;
    height: 64px;
  }
}

.content {
  h2 {
    margin-bottom: 24px;
  }
}

.media {
  width: 100%;
  max-width: 800px;
  border-radius: 8px;
}

.document {
  width: 100%;
  height: 80vh;
  border: 1px solid #ddd;
  border-radius: 8px;
}

.file-info {
  padding: 24px;
  background: #f5f5f5;
  border-radius: 8px;
  text-align: center;
  
  mat-icon {
    font-size: 64px;
    width: 64px;
    height: 64px;
    margin-bottom: 16px;
  }
  
  p {
    margin: 8px 0;
  }
  
  a {
    margin-top: 16px;
  }
}
'@

Set-Content -Path "src/app/components/viewer/viewer.component.ts" -Value $viewerTs
Set-Content -Path "src/app/components/viewer/viewer.component.html" -Value $viewerHtml
Set-Content -Path "src/app/components/viewer/viewer.component.scss" -Value $viewerScss

# =====================================
# ADMIN COMPONENT
# =====================================
Write-Host "Creating admin component..." -ForegroundColor Cyan

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
      
      <div *ngIf="message" class="message" [class.error]="isError">
        <mat-icon>{{ isError ? 'error' : 'check_circle' }}</mat-icon>
        {{ message }}
      </div>
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

.back-button {
  margin-bottom: 16px;
}

mat-card {
  margin: 24px 0;
}

.full-width {
  width: 100%;
  margin: 16px 0;
}

button[mat-raised-button] {
  margin-top: 8px;
}

.message {
  margin-top: 16px;
  padding: 12px;
  border-radius: 4px;
  background: #4caf50;
  color: white;
  display: flex;
  align-items: center;
  gap: 8px;
  
  &.error {
    background: #f44336;
  }
}
'@

Set-Content -Path "src/app/components/admin/admin.component.ts" -Value $adminTs
Set-Content -Path "src/app/components/admin/admin.component.html" -Value $adminHtml
Set-Content -Path "src/app/components/admin/admin.component.scss" -Value $adminScss

# =====================================
# MAIN LAYOUT COMPONENT
# =====================================
Write-Host "Creating main layout component..." -ForegroundColor Cyan

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

Set-Content -Path "src/app/components/main-layout/main-layout.component.ts" -Value $mainLayoutTs
Set-Content -Path "src/app/components/main-layout/main-layout.component.html" -Value $mainLayoutHtml
Set-Content -Path "src/app/components/main-layout/main-layout.component.scss" -Value $mainLayoutScss

# =====================================
# APP MODULE
# =====================================
Write-Host "Creating app module..." -ForegroundColor Cyan

$appModuleTs = @'
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { RouterModule, Routes } from '@angular/router';

import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTreeModule } from '@angular/material/tree';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';

import { AppComponent } from './app.component';
import { HeaderComponent } from './components/header/header.component';
import { SidebarComponent } from './components/sidebar/sidebar.component';
import { ViewerComponent } from './components/viewer/viewer.component';
import { AdminComponent } from './components/admin/admin.component';
import { MainLayoutComponent } from './components/main-layout/main-layout.component';

const routes: Routes = [
  { path: '', component: MainLayoutComponent },
  { path: 'admin', component: AdminComponent }
];

@NgModule({
  declarations: [
    AppComponent,
    HeaderComponent,
    SidebarComponent,
    ViewerComponent,
    AdminComponent,
    MainLayoutComponent
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    FormsModule,
    RouterModule.forRoot(routes),
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatTreeModule,
    MatCardModule,
    MatFormFieldModule,
    MatInputModule
  ],
  providers: [
    provideHttpClient(withInterceptorsFromDi())
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
'@

Set-Content -Path "src/app/app.module.ts" -Value $appModuleTs -Force

# =====================================
# APP COMPONENT
# =====================================
Write-Host "Updating app component..." -ForegroundColor Cyan

$appComponentTs = @'
import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent {
  title = 'LMS System';
}
'@

$appComponentHtml = @'
<router-outlet></router-outlet>
'@

Set-Content -Path "src/app/app.component.ts" -Value $appComponentTs -Force
Set-Content -Path "src/app/app.component.html" -Value $appComponentHtml -Force

Write-Host ""
Write-Host "=== Angular UI Recreation Complete! ===" -ForegroundColor Green
Write-Host "Modern Angular 19 with Node v24 compatibility" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: part3-create-database.ps1" -ForegroundColor White
Write-Host "2. Run: part4-create-samples.ps1" -ForegroundColor White
Write-Host "3. Start system: run-all.bat" -ForegroundColor White
Write-Host ""