import { Component, OnInit, Output, EventEmitter, ChangeDetectorRef, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CourseService } from '../../services/course.service';
import { CourseItem } from '../../models/course.model';

interface TreeNode extends CourseItem {
  expanded?: boolean;
  level?: number;
  loading?: boolean;
}

@Component({
  selector: 'app-tree-node',
  standalone: true,
  imports: [CommonModule, MatIconModule, MatButtonModule, MatProgressSpinnerModule],
  template: `
    <div class="tree-node">
      <!-- Node Row -->
      <div class="node-row" [style.padding-left.px]="node.level! * 24">
        <!-- Toggle button for folders -->
        @if (isFolder) {
          <button mat-icon-button class="toggle-btn" (click)="onToggle()">
            <mat-icon>{{ node.expanded ? 'expand_more' : 'chevron_right' }}</mat-icon>
          </button>
        } @else {
          <span class="spacer"></span>
        }
        
        <!-- Node content -->
        <div class="node-content" 
             [class.selected]="isSelected"
             (click)="onClick()">
          <mat-icon class="node-icon" [style.color]="iconColor">{{ icon }}</mat-icon>
          <span class="node-name" [title]="node.name">{{ node.name }}</span>
        </div>
      </div>
      
      <!-- Loading indicator -->
      @if (node.loading) {
        <div class="loading-item" [style.padding-left.px]="(node.level! + 1) * 24">
          <mat-spinner diameter="20"></mat-spinner>
          <span>Loading...</span>
        </div>
      }
      
      <!-- Children -->
      @if (node.expanded && node.children && node.children.length > 0) {
        @for (child of node.children; track child.id) {
          <app-tree-node 
            [node]="child" 
            [selectedId]="selectedId"
            (nodeToggle)="onChildToggle($event)"
            (nodeSelect)="onChildSelect($event)">
          </app-tree-node>
        }
      }
    </div>
  `,
  styles: [`
    .node-row {
      display: flex;
      align-items: center;
      min-height: 40px;
      transition: background 0.2s;
    }
    
    .node-row:hover {
      background: rgba(0, 0, 0, 0.04);
    }
    
    .toggle-btn {
      width: 32px;
      height: 32px;
      flex-shrink: 0;
      margin-right: 4px;
    }
    
    .spacer {
      width: 36px;
      flex-shrink: 0;
    }
    
    .toggle-btn mat-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
    }
    
    .node-content {
      display: flex;
      align-items: center;
      gap: 8px;
      flex: 1;
      padding: 8px;
      border-radius: 4px;
      cursor: pointer;
    }
    
    .node-content.selected {
      background: rgba(63, 81, 181, 0.1);
      border-left: 3px solid #3f51b5;
    }
    
    .node-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
      flex-shrink: 0;
    }
    
    .node-name {
      font-size: 14px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    
    .loading-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px;
      font-size: 12px;
      color: #666;
    }
  `]
})
export class TreeNodeComponent {
  @Input() node!: TreeNode;
  @Input() selectedId: number | null = null;
  @Output() nodeToggle = new EventEmitter<TreeNode>();
  @Output() nodeSelect = new EventEmitter<TreeNode>();

  get isFolder(): boolean {
    return this.node.type === 'folder';
  }

  get isSelected(): boolean {
    return this.selectedId === this.node.id;
  }

  get icon(): string {
    const type = this.node.type;
    const ext = this.node.extension.toLowerCase();
    
    if (type === 'course') return 'school';
    if (type === 'folder') return 'folder';
    
    if (['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.webm'].includes(ext)) return 'play_circle_outline';
    if (['.mp3', '.wav', '.ogg', '.m4a'].includes(ext)) return 'audiotrack';
    if (ext === '.pdf') return 'picture_as_pdf';
    if (['.doc', '.docx'].includes(ext)) return 'description';
    if (['.txt', '.md'].includes(ext)) return 'article';
    if (['.jpg', '.jpeg', '.png', '.gif'].includes(ext)) return 'image';
    
    return 'insert_drive_file';
  }

  get iconColor(): string {
    const ext = this.node.extension.toLowerCase();
    
    if (['.mp4', '.avi', '.mkv'].includes(ext)) return '#e53935';
    if (['.mp3', '.wav'].includes(ext)) return '#5e35b1';
    if (ext === '.pdf') return '#d32f2f';
    if (['.doc', '.docx'].includes(ext)) return '#1976d2';
    if (['.txt', '.md'].includes(ext)) return '#424242';
    
    return '#757575';
  }

  onToggle() {
    this.nodeToggle.emit(this.node);
  }

  onClick() {
    if (this.isFolder || this.node.type === 'course') {
      this.onToggle();
    } else {
      this.nodeSelect.emit(this.node);
    }
  }

  onChildToggle(node: TreeNode) {
    this.nodeToggle.emit(node);
  }

  onChildSelect(node: TreeNode) {
    this.nodeSelect.emit(node);
  }
}

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, MatIconModule, MatButtonModule, MatProgressSpinnerModule, TreeNodeComponent],
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
      
      @if (!loading && !error && courses.length === 0) {
        <div class="empty-state">
          <mat-icon>school</mat-icon>
          <p>No courses found</p>
          <p class="hint">Use Admin panel to scan courses</p>
        </div>
      }
      
      @if (!loading && !error && courses.length > 0) {
        <div class="tree-container">
          @for (course of courses; track course.id) {
            <app-tree-node 
              [node]="course" 
              [selectedId]="selectedItemId"
              (nodeToggle)="toggleNode($event)"
              (nodeSelect)="selectFile($event)">
            </app-tree-node>
          }
        </div>
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
    
    .tree-container {
      width: 100%;
    }
  `]
})
export class SidebarComponent implements OnInit {
  @Output() fileSelected = new EventEmitter<CourseItem>();
  
  courses: TreeNode[] = [];
  loading = false;
  error = '';
  selectedItemId: number | null = null;
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
    
    this.courseService.getCourses().subscribe({
      next: (courses) => {
        if (courses.length === 0) {
          this.loading = false;
          this.courses = [];
          return;
        }
        
        let completed = 0;
        const treeNodes: TreeNode[] = [];
        
        courses.forEach(course => {
          this.courseService.getCourseItems(course.id).subscribe({
            next: (items) => {
              treeNodes.push({
                id: course.id,
                courseId: course.id,
                name: course.name,
                path: course.path,
                type: 'course',
                extension: '',
                size: 0,
                children: items.map(item => ({ ...item, level: 1 })),
                expanded: false,
                level: 0
              });
              completed++;
              
              if (completed === courses.length) {
                this.courses = treeNodes;
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

  toggleNode(node: TreeNode) {
    node.expanded = !node.expanded;
    
    // Load folder contents if expanding a folder for the first time
    if (node.expanded && node.type === 'folder' && !this.loadedNodes.has(node.id)) {
      this.loadFolderContents(node);
    }
    
    this.cdr.detectChanges();
  }

  loadFolderContents(node: TreeNode) {
    if (this.loadedNodes.has(node.id)) {
      return;
    }

    node.loading = true;
    this.cdr.detectChanges();

    this.courseService.getFolderContents(node.id).subscribe({
      next: (children) => {
        node.children = children.map(child => ({
          ...child,
          expanded: false,
          level: (node.level || 0) + 1
        }));
        node.loading = false;
        this.loadedNodes.add(node.id);
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Failed to load folder contents:', err);
        node.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  selectFile(node: TreeNode) {
    if (node.type !== 'folder' && node.type !== 'course') {
      this.selectedItemId = node.id;
      this.fileSelected.emit(node);
      this.cdr.detectChanges();
    }
  }
}
