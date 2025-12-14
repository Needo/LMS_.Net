# Complete LMS Angular Fix - One Command
# This rebuilds EVERYTHING correctly

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== COMPLETE LMS ANGULAR REBUILD ===" -ForegroundColor Green
Write-Host "This will take 5-10 minutes but will work!" -ForegroundColor Cyan
Write-Host ""

Set-Location $RootPath

# Clean everything
Write-Host "[1/8] Cleaning old files..." -ForegroundColor Yellow
Remove-Item -Recurse -Force "LMSUI" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "src" -ErrorAction SilentlyContinue
Remove-Item -Force "package-lock.json" -ErrorAction SilentlyContinue

# Update Angular CLI
Write-Host "[2/8] Updating Angular CLI..." -ForegroundColor Yellow
npm install -g @angular/cli@latest

# Create new project
Write-Host "[3/8] Creating Angular project..." -ForegroundColor Yellow
ng new LMSUI --routing=true --style=scss --ssr=false --skip-git=true

Set-Location "$RootPath\LMSUI"

# Install Material
Write-Host "[4/8] Installing Angular Material..." -ForegroundColor Yellow
ng add @angular/material --defaults

# Fix styles
Write-Host "[5/8] Configuring styles..." -ForegroundColor Yellow
$styles = @'
@import '@angular/material/prebuilt-themes/indigo-pink.css';
html, body { height: 100%; margin: 0; font-family: Roboto, sans-serif; }
'@
Set-Content -Path "src/styles.scss" -Value $styles

# Create directories
Write-Host "[6/8] Creating structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "src/app/models" | Out-Null
New-Item -ItemType Directory -Force -Path "src/app/services" | Out-Null

# Models
$models = @'
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
Set-Content -Path "src/app/models/course.model.ts" -Value $models

# Service
$service = @'
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Course, CourseItem } from '../models/course.model';

@Injectable({ providedIn: 'root' })
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
Set-Content -Path "src/app/services/course.service.ts" -Value $service

# Generate components
Write-Host "[7/8] Generating components..." -ForegroundColor Yellow
ng g c components/header --skip-tests
ng g c components/sidebar --skip-tests
ng g c components/viewer --skip-tests
ng g c components/admin --skip-tests
ng g c components/main-layout --skip-tests

# Update each component
Write-Host "[8/8] Configuring components..." -ForegroundColor Yellow

# Header
$headerTs = @'
import { Component } from '@angular/core';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [MatToolbarModule, MatButtonModule, MatIconModule, RouterModule],
  template: `
    <mat-toolbar color="primary">
      <span>Learning Management System</span>
      <span class="spacer"></span>
      <button mat-button routerLink="/admin">
        <mat-icon>settings</mat-icon>
        Admin
      </button>
    </mat-toolbar>
  `,
  styles: ['.spacer { flex: 1 1 auto; }']
})
export class HeaderComponent {}
'@
Set-Content -Path "src/app/components/header/header.component.ts" -Value $headerTs -Force

# Sidebar
$sidebarTs = @'
import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NestedTreeControl } from '@angular/cdk/tree';
import { MatTreeModule, MatTreeNestedDataSource } from '@angular/material/tree';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { CourseService } from '../../services/course.service';
import { CourseItem } from '../../models/course.model';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, MatTreeModule, MatIconModule, MatButtonModule],
  template: `
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
                <mat-icon>{{ treeControl.isExpanded(node) ? 'expand_more' : 'chevron_right' }}</mat-icon>
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
  `,
  styles: [`
    .sidebar { width: 300px; background: #f5f5f5; overflow-y: auto; border-right: 1px solid #ddd; padding: 16px; }
    .mat-tree { background: transparent; }
    .mat-tree-node { min-height: 40px; display: flex; align-items: center; }
    .node-label { display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 4px 8px; border-radius: 4px; }
    .node-label:hover { background: rgba(0,0,0,0.05); }
    ul { padding-left: 20px; list-style: none; }
    .hidden { display: none; }
  `]
})
export class SidebarComponent implements OnInit {
  @Output() fileSelected = new EventEmitter<CourseItem>();
  treeControl = new NestedTreeControl<CourseItem>(node => node.children);
  dataSource = new MatTreeNestedDataSource<CourseItem>();

  constructor(private courseService: CourseService) {}

  ngOnInit() {
    this.courseService.getCourses().subscribe(courses => {
      const items: CourseItem[] = [];
      let completed = 0;
      if (courses.length === 0) return;
      courses.forEach(course => {
        this.courseService.getCourseItems(course.id).subscribe(courseItems => {
          items.push({
            id: course.id, courseId: course.id, name: course.name,
            path: course.path, type: 'course', extension: '', size: 0,
            children: courseItems
          });
          if (++completed === courses.length) this.dataSource.data = items;
        });
      });
    });
  }

  hasChild = (_: number, node: CourseItem) => !!node.children && node.children.length > 0;
  toggleNode(node: CourseItem) { this.treeControl.toggle(node); }
  selectItem(node: CourseItem) {
    if (node.type !== 'folder' && node.type !== 'course') this.fileSelected.emit(node);
  }
  getIcon(type: string): string {
    const icons: any = { course: 'school', folder: 'folder', video: 'video_library', audio: 'audiotrack', document: 'description' };
    return icons[type] || 'insert_drive_file';
  }
}
'@
Set-Content -Path "src/app/components/sidebar/sidebar.component.ts" -Value $sidebarTs -Force

# Viewer
$viewerTs = @'
import { Component, Input, OnChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { CourseItem } from '../../models/course.model';
import { CourseService } from '../../services/course.service';

@Component({
  selector: 'app-viewer',
  standalone: true,
  imports: [CommonModule, MatIconModule, MatButtonModule],
  template: `
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
              <mat-icon>description</mat-icon>
              <p>{{ selectedItem.name }}</p>
              <p>Size: {{ formatSize(selectedItem.size) }}</p>
              <a [href]="fileUrl" download mat-raised-button color="primary">
                <mat-icon>download</mat-icon> Download
              </a>
            </div>
          }
        </div>
      }
    </div>
  `,
  styles: [`
    .viewer { flex: 1; padding: 24px; overflow-y: auto; background: white; }
    .placeholder { display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; color: #999; }
    .placeholder mat-icon { font-size: 64px; width: 64px; height: 64px; }
    .content h2 { margin-bottom: 24px; }
    .media { width: 100%; max-width: 800px; border-radius: 8px; }
    .document { width: 100%; height: 80vh; border: 1px solid #ddd; border-radius: 8px; }
    .file-info { padding: 24px; background: #f5f5f5; border-radius: 8px; text-align: center; }
    .file-info mat-icon { font-size: 64px; width: 64px; height: 64px; margin-bottom: 16px; }
  `]
})
export class ViewerComponent implements OnChanges {
  @Input() selectedItem: CourseItem | null = null;
  fileUrl: string = '';

  constructor(private courseService: CourseService, private sanitizer: DomSanitizer) {}

  ngOnChanges() {
    if (this.selectedItem) this.fileUrl = this.courseService.getFileUrl(this.selectedItem.path);
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
Set-Content -Path "src/app/components/viewer/viewer.component.ts" -Value $viewerTs -Force

# Admin
$adminTs = @'
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { CourseService } from '../../services/course.service';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [CommonModule, FormsModule, MatCardModule, MatFormFieldModule, MatInputModule, MatButtonModule, MatIconModule],
  template: `
    <div class="admin-panel">
      <button mat-icon-button (click)="goBack()">
        <mat-icon>arrow_back</mat-icon>
      </button>
      <h1>Admin Panel</h1>
      <mat-card>
        <mat-card-header><mat-card-title>Course Scanner</mat-card-title></mat-card-header>
        <mat-card-content>
          <p>Scan a directory to import courses.</p>
          <mat-form-field appearance="outline" class="full-width">
            <mat-label>Root Path</mat-label>
            <input matInput [(ngModel)]="rootPath" placeholder="C:\\Courses">
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
  `,
  styles: [`
    .admin-panel { padding: 24px; max-width: 800px; margin: 0 auto; }
    .full-width { width: 100%; margin: 16px 0; }
    .message { margin-top: 16px; padding: 12px; border-radius: 4px; background: #4caf50; color: white; display: flex; align-items: center; gap: 8px; }
    .message.error { background: #f44336; }
  `]
})
export class AdminComponent {
  rootPath = 'C:\\Courses';
  scanning = false;
  message = '';
  isError = false;

  constructor(private courseService: CourseService, private router: Router) {}

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

  goBack() { this.router.navigate(['/']); }
}
'@
Set-Content -Path "src/app/components/admin/admin.component.ts" -Value $adminTs -Force

# Main Layout
$mainLayoutTs = @'
import { Component } from '@angular/core';
import { HeaderComponent } from '../header/header.component';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { ViewerComponent } from '../viewer/viewer.component';
import { CourseItem } from '../../models/course.model';

@Component({
  selector: 'app-main-layout',
  standalone: true,
  imports: [HeaderComponent, SidebarComponent, ViewerComponent],
  template: `
    <div class="app-container">
      <app-header></app-header>
      <div class="content-container">
        <app-sidebar (fileSelected)="onFileSelected($event)"></app-sidebar>
        <app-viewer [selectedItem]="selectedItem"></app-viewer>
      </div>
    </div>
  `,
  styles: [`
    .app-container { display: flex; flex-direction: column; height: 100vh; }
    .content-container { display: flex; flex: 1; overflow: hidden; }
  `]
})
export class MainLayoutComponent {
  selectedItem: CourseItem | null = null;
  onFileSelected(item: CourseItem) { this.selectedItem = item; }
}
'@
Set-Content -Path "src/app/components/main-layout/main-layout.component.ts" -Value $mainLayoutTs -Force

# App Routes
$routes = @'
import { Routes } from '@angular/router';
import { MainLayoutComponent } from './components/main-layout/main-layout.component';
import { AdminComponent } from './components/admin/admin.component';

export const routes: Routes = [
  { path: '', component: MainLayoutComponent },
  { path: 'admin', component: AdminComponent }
];
'@
Set-Content -Path "src/app/app.routes.ts" -Value $routes -Force

# App Component
$appComp = @'
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
Set-Content -Path "src/app/app.component.ts" -Value $appComp -Force

Write-Host ""
Write-Host "=== BUILD COMPLETE! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Starting dev server..." -ForegroundColor Yellow
ng serve --open