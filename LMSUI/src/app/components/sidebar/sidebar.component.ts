import { Component, OnInit, Output, EventEmitter, ChangeDetectorRef } from '@angular/core';
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
          <!-- Leaf nodes (files) -->
          <mat-tree-node *matTreeNodeDef="let node" matTreeNodePadding [matTreeNodePaddingIndent]="24">
            <button mat-icon-button disabled class="tree-toggle-btn"></button>
            <span (click)="selectItem(node)" class="node-label" [class.selected]="isSelected(node)">
              <mat-icon class="node-icon" [style.color]="getIconColor(node.extension)">
                {{ getIcon(node.type, node.extension) }}
              </mat-icon>
              <span class="node-name" [title]="node.name">{{ node.name }}</span>
            </span>
          </mat-tree-node>
          
          <!-- Branch nodes (folders/courses) -->
          <mat-nested-tree-node *matTreeNodeDef="let node; when: hasChild" matTreeNodePadding [matTreeNodePaddingIndent]="24">
            <div class="tree-node-wrapper">
              <button mat-icon-button (click)="toggleNodeAndLoad(node)" class="tree-toggle-btn">
                <mat-icon class="toggle-icon">
                  {{ treeControl.isExpanded(node) ? 'expand_more' : 'chevron_right' }}
                </mat-icon>
              </button>
              <span (click)="toggleNodeAndLoad(node)" class="node-label">
                <mat-icon class="node-icon">{{ getIcon(node.type, node.extension) }}</mat-icon>
                <span class="node-name" [title]="node.name">{{ node.name }}</span>
              </span>
            </div>
            <div [class.tree-invisible]="!treeControl.isExpanded(node)" class="tree-children">
              @if (loadingNodes.has(node.id)) {
                <div class="loading-node">
                  <mat-spinner diameter="20"></mat-spinner>
                  <span>Loading...</span>
                </div>
              }
              <ng-container matTreeNodeOutlet></ng-container>
            </div>
          </mat-nested-tree-node>
        </mat-tree>
      }
    </div>
  `,
  styles: [`
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
    
    .loading-node {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px;
      font-size: 12px;
      color: #666;
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
      overflow-x: hidden;
      overflow-y: auto;
    }

    .course-tree .mat-tree-node {
      min-height: 36px;
    }

    .tree-children { padding-left: 24px; }
    
    .tree-node-wrapper {
      display: flex;
      align-items: center;
      min-height: 36px;
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
      padding: 6px 8px; 
      border-radius: 4px; 
      flex: 1;
      min-height: 36px;
      min-width: 0;
      transition: background 0.15s;
    }
    
    .node-label:hover { 
      background: rgba(0,0,0,0.08); 
    }

    .node-label.selected {
      background: rgba(63, 81, 181, 0.1);
      border-left: 3px solid #3f51b5;
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
      font-size: 14px;
    }
    
    .tree-invisible {
      display: none;
    }
    
    .mat-tree-node {
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
  selectedItemId: number | null = null;
  loadingNodes = new Set<number>();
  loadedNodes = new Set<number>();

  constructor(
    private courseService: CourseService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit() {
    this.loadCourses();
  }

  loadCourses() {
    this.loading = true;
    this.error = '';
    this.cdr.detectChanges();
    
    this.courseService.getCourses().subscribe({
      next: (courses) => {
        if (courses.length === 0) {
          this.loading = false;
          this.dataSource.data = [];
          this.cdr.detectChanges();
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
                this.cdr.detectChanges();
              }
            },
            error: (err) => {
              this.loading = false;
              this.error = 'Failed to load course items: ' + err.message;
              this.cdr.detectChanges();
            }
          });
        });
      },
      error: (err) => {
        this.loading = false;
        this.error = err.message;
        this.cdr.detectChanges();
      }
    });
  }

  toggleNodeAndLoad(node: CourseItem) {
    // If expanding and folder type, load children
    if (!this.treeControl.isExpanded(node) && node.type === 'folder' && !this.loadedNodes.has(node.id)) {
      this.loadFolderContents(node);
    }
    this.treeControl.toggle(node);
  }

  loadFolderContents(node: CourseItem) {
    if (this.loadedNodes.has(node.id)) {
      return; // Already loaded
    }

    this.loadingNodes.add(node.id);
    this.cdr.detectChanges();

    this.courseService.getFolderContents(node.id).subscribe({
      next: (children) => {
        node.children = children;
        this.loadedNodes.add(node.id);
        this.loadingNodes.delete(node.id);
        
        // Update the data source to trigger change detection
        this.dataSource.data = [...this.dataSource.data];
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Failed to load folder contents:', err);
        this.loadingNodes.delete(node.id);
        this.cdr.detectChanges();
      }
    });
  }

  hasChild = (_: number, node: CourseItem) => {
    // A node has children if it's a folder or course
    return node.type === 'folder' || node.type === 'course';
  };
  
  selectItem(node: CourseItem) {
    if (node.type !== 'folder' && node.type !== 'course') {
      this.selectedItemId = node.id;
      this.fileSelected.emit(node);
      this.cdr.detectChanges();
    }
  }

  isSelected(node: CourseItem): boolean {
    return this.selectedItemId === node.id;
  }
  
  getIcon(type: string, extension: string): string {
    if (type !== 'course' && type !== 'folder') {
      const ext = extension.toLowerCase();
      
      if (['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.webm', '.flv', '.m4v'].includes(ext)) {
        return 'play_circle_outline';
      }
      if (['.mp3', '.wav', '.ogg', '.m4a', '.flac', '.aac'].includes(ext)) {
        return 'audiotrack';
      }
      if (ext === '.pdf') {
        return 'picture_as_pdf';
      }
      if (['.doc', '.docx'].includes(ext)) {
        return 'description';
      }
      if (['.xls', '.xlsx'].includes(ext)) {
        return 'table_chart';
      }
      if (['.ppt', '.pptx'].includes(ext)) {
        return 'slideshow';
      }
      if (['.txt', '.md', '.log'].includes(ext)) {
        return 'article';
      }
      if (['.js', '.ts', '.html', '.css', '.json', '.xml', '.py', '.java', '.cs', '.cpp'].includes(ext)) {
        return 'code';
      }
      if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp'].includes(ext)) {
        return 'image';
      }
      if (['.zip', '.rar', '.7z', '.tar', '.gz'].includes(ext)) {
        return 'folder_zip';
      }
      if (['.epub', '.mobi', '.azw', '.azw3'].includes(ext)) {
        return 'menu_book';
      }
      
      return 'insert_drive_file';
    }
    
    if (type === 'folder') {
      return 'folder';
    }
    
    if (type === 'course') {
      return 'school';
    }
    
    return 'insert_drive_file';
  }

  getIconColor(extension: string): string {
    const ext = extension.toLowerCase();
    
    if (['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.webm'].includes(ext)) {
      return '#e53935';
    }
    if (['.mp3', '.wav', '.ogg', '.m4a'].includes(ext)) {
      return '#5e35b1';
    }
    if (ext === '.pdf') {
      return '#d32f2f';
    }
    if (['.doc', '.docx'].includes(ext)) {
      return '#1976d2';
    }
    if (['.xls', '.xlsx'].includes(ext)) {
      return '#388e3c';
    }
    if (['.ppt', '.pptx'].includes(ext)) {
      return '#f57c00';
    }
    if (['.epub', '.mobi', '.azw', '.azw3'].includes(ext)) {
      return '#6d4c41';
    }
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg'].includes(ext)) {
      return '#00acc1';
    }
    
    return '#757575';
  }
}
