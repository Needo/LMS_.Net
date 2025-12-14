# Fix Component Imports for Angular 19
# Angular 19 uses standalone components that need explicit imports

param(
    [string]$RootPath = "C:\LMSSystem"
)

Write-Host "=== Fixing Component Imports ===" -ForegroundColor Green

Set-Location "$RootPath\LMSUI\src\app\components"

# =====================================
# HEADER COMPONENT
# =====================================
Write-Host "Updating header component..." -ForegroundColor Yellow

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
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.scss']
})
export class HeaderComponent {}
'@

Set-Content -Path "header/header.component.ts" -Value $headerTs -Force

# =====================================
# SIDEBAR COMPONENT
# =====================================
Write-Host "Updating sidebar component..." -ForegroundColor Yellow

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

Set-Content -Path "sidebar/sidebar.component.ts" -Value $sidebarTs -Force

# =====================================
# VIEWER COMPONENT
# =====================================
Write-Host "Updating viewer component..." -ForegroundColor Yellow

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

Set-Content -Path "viewer/viewer.component.ts" -Value $viewerTs -Force

# =====================================
# ADMIN COMPONENT
# =====================================
Write-Host "Updating admin component..." -ForegroundColor Yellow

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
  imports: [
    CommonModule, 
    FormsModule,
    MatCardModule, 
    MatFormFieldModule, 
    MatInputModule, 
    MatButtonModule, 
    MatIconModule
  ],
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

Set-Content -Path "admin/admin.component.ts" -Value $adminTs -Force

# =====================================
# MAIN LAYOUT COMPONENT
# =====================================
Write-Host "Updating main-layout component..." -ForegroundColor Yellow

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

Set-Content -Path "main-layout/main-layout.component.ts" -Value $mainLayoutTs -Force

# =====================================
# APP COMPONENT
# =====================================
Write-Host "Updating app component..." -ForegroundColor Yellow

Set-Location "$RootPath\LMSUI\src\app"

$appComponentTs = @'
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent {
  title = 'LMS System';
}
'@

Set-Content -Path "app.component.ts" -Value $appComponentTs -Force

Write-Host ""
Write-Host "=== All Components Updated! ===" -ForegroundColor Green
Write-Host ""
Write-Host "All components are now standalone with proper imports" -ForegroundColor Green
Write-Host ""
Write-Host "Try running:" -ForegroundColor Yellow
Write-Host "  ng serve" -ForegroundColor White
Write-Host ""