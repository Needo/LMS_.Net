import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NestedTreeControl } from '@angular/cdk/tree';
import { MatTreeModule, MatTreeNestedDataSource } from '@angular/material/tree';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CourseService } from '../../services/course.service';
import { CourseItem } from '../../models/course.model';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, MatTreeModule, MatIconModule, MatButtonModule, MatProgressSpinnerModule],
  template: `
    <div class="sidebar">
      <h3>Courses</h3>
      
      @if (loading) {
        <div class="loading">
          <mat-spinner diameter="40"></mat-spinner>
          <p>Loading courses...</p>
        </div>
      }
      
      @if (error) {
        <div class="error-message">
          <mat-icon>error</mat-icon>
          <p>{{ error }}</p>
          <button mat-raised-button color="primary" (click)="loadCourses()">Retry</button>
        </div>
      }
      
      @if (!loading && !error && dataSource.data.length === 0) {
        <div class="empty-state">
          <mat-icon>school</mat-icon>
          <p>No courses found</p>
          <p class="hint">Use Admin panel to scan courses</p>
        </div>
      }
      
      @if (!loading && !error && dataSource.data.length > 0) {
        <mat-tree [dataSource]="dataSource" [treeControl]="treeControl" class="course-tree">
          <mat-tree-node *matTreeNodeDef="let node" matTreeNodePadding matTreeNodePaddingIndent="20">
            <button mat-icon-button disabled class="tree-toggle-btn"></button>
            <span (click)="selectItem(node)" class="node-label">
              <mat-icon class="node-icon">{{ getIcon(node.type) }}</mat-icon>
              <span class="node-name">{{ node.name }}</span>
            </span>
          </mat-tree-node>
          
          <mat-nested-tree-node *matTreeNodeDef="let node; when: hasChild" matTreeNodePadding matTreeNodePaddingIndent="20">
            <div class="tree-node-wrapper">
              <button mat-icon-button matTreeNodeToggle class="tree-toggle-btn">
                <mat-icon class="toggle-icon">
                  {{ treeControl.isExpanded(node) ? 'expand_more' : 'chevron_right' }}
                </mat-icon>
              </button>
              <span (click)="toggleNode(node)" class="node-label">
                <mat-icon class="node-icon">{{ getIcon(node.type) }}</mat-icon>
                <span class="node-name">{{ node.name }}</span>
              </span>
            </div>
            <div [class.tree-invisible]="!treeControl.isExpanded(node)">
              <ng-container matTreeNodeOutlet></ng-container>
            </div>
          </mat-nested-tree-node>
        </mat-tree>
      }
    </div>
  `,
  styles: [`
    .sidebar { 
      width: 300px; 
      background: #f5f5f5; 
      height: 100%;
      overflow-y: auto; 
      border-right: 1px solid #ddd; 
      padding: 16px; 
      display: flex;
      flex-direction: column;
    }
    
    h3 { 
      margin: 0 0 16px 0; 
      color: #333; 
      font-size: 18px;
      font-weight: 500;
    }
    
    .loading, .error-message, .empty-state { 
      text-align: center; 
      padding: 24px;
      color: #666;
    }
    
    .loading mat-spinner {
      margin: 0 auto 16px;
    }
    
    .error-message {
      background: #ffebee;
      border-radius: 8px;
      padding: 16px;
    }
    
    .error-message mat-icon {
      color: #c62828;
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 8px;
    }
    
    .error-message button {
      margin-top: 12px;
    }
    
    .empty-state mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      color: #ccc;
    }
    
    .empty-state .hint {
      font-size: 12px;
      color: #999;
      margin-top: 8px;
    }
    
    .course-tree { 
      background: transparent;
      flex: 1;
    }
    
    .tree-node-wrapper {
      display: flex;
      align-items: center;
      height: 40px;
    }
    
    .tree-toggle-btn {
      width: 24px;
      height: 24px;
      padding: 0;
      margin-right: 4px;
      flex-shrink: 0;
    }
    
    .tree-toggle-btn .toggle-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
      line-height: 20px;
    }
    
    .node-label { 
      display: flex; 
      align-items: center; 
      gap: 8px; 
      cursor: pointer; 
      padding: 8px 12px; 
      border-radius: 4px; 
      flex: 1;
      min-height: 40px;
    }
    
    .node-label:hover { 
      background: rgba(0,0,0,0.05); 
    }
    
    .node-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
      flex-shrink: 0;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .node-name {
      flex: 1;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    
    .tree-invisible {
      display: none;
    }
    
    .mat-tree-node {
      min-height: 40px;
      display: flex;
      align-items: center;
    }
  `]
})
export class SidebarComponent implements OnInit {
  @Output() fileSelected = new EventEmitter<CourseItem>();
  treeControl = new NestedTreeControl<CourseItem>(node => node.children);
  dataSource = new MatTreeNestedDataSource<CourseItem>();
  loading = false;
  error = '';

  constructor(private courseService: CourseService) {}

  ngOnInit() {
    this.loadCourses();
  }

  loadCourses() {
    this.loading = true;
    this.error = '';
    
    this.courseService.getCourses().subscribe({
      next: (courses) => {
        if (courses.length === 0) {
          this.loading = false;
          this.dataSource.data = [];
          return;
        }
        
        const items: CourseItem[] = [];
        let completed = 0;
        
        courses.forEach(course => {
          this.courseService.getCourseItems(course.id).subscribe({
            next: (courseItems) => {
              items.push({
                id: course.id, 
                courseId: course.id, 
                name: course.name,
                path: course.path, 
                type: 'course', 
                extension: '', 
                size: 0,
                children: courseItems
              });
              completed++;
              
              if (completed === courses.length) {
                this.dataSource.data = items;
                this.loading = false;
              }
            },
            error: (err) => {
              this.loading = false;
              this.error = 'Failed to load course items: ' + err.message;
            }
          });
        });
      },
      error: (err) => {
        this.loading = false;
        this.error = err.message;
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
    const icons: any = { 
      course: 'school', 
      folder: 'folder', 
      video: 'video_library', 
      audio: 'audiotrack', 
      document: 'description' 
    };
    return icons[type] || 'insert_drive_file';
  }
}
