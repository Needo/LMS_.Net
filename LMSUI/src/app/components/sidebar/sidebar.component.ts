import { Component, OnInit, Output, EventEmitter, ChangeDetectorRef, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { CourseService } from '../../services/course.service';
import { CourseItem, Category, Course } from '../../models/course.model';
import { SearchResult } from '../../services/search.service';

interface TreeNode {
  id: number;
  courseId?: number;
  name: string;
  path: string;
  type: 'category' | 'course' | 'folder' | string;
  extension: string;
  size: number;
  children?: TreeNode[];
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
      <div class="node-row" [style.padding-left.px]="node.level! * 24">
        @if (hasChildren) {
          <button mat-icon-button class="toggle-btn" (click)="onToggle()">
            <mat-icon>{{ node.expanded ? 'expand_more' : 'chevron_right' }}</mat-icon>
          </button>
        } @else {
          <span class="spacer"></span>
        }
        
        <div class="node-content" 
             [class.selected]="isSelected"
             (click)="onClick()">
          <mat-icon class="node-icon" [style.color]="iconColor">{{ icon }}</mat-icon>
          <span class="node-name" [title]="node.name">{{ node.name }}</span>
        </div>
      </div>
      
      @if (node.loading) {
        <div class="loading-item" [style.padding-left.px]="(node.level! + 1) * 24">
          <mat-spinner diameter="20"></mat-spinner>
          <span>Loading...</span>
        </div>
      }
      
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
    .node-row { display: flex; align-items: center; min-height: 36px; transition: background 0.2s; }
    .node-row:hover { background: rgba(0, 0, 0, 0.04); }
    .toggle-btn { width: 36px; height: 36px; line-height: 36px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; padding: 0; }
    .spacer { width: 36px; height: 36px; flex-shrink: 0; }
    .toggle-btn mat-icon { font-size: 20px; width: 20px; height: 20px; line-height: 20px; }
    .node-content { display: flex; align-items: center; gap: 8px; flex: 1; padding: 6px 8px; border-radius: 4px; cursor: pointer; min-height: 36px; }
    .node-content.selected { background: rgba(63, 81, 181, 0.1); border-left: 3px solid #3f51b5; }
    .node-icon { font-size: 20px; width: 20px; height: 20px; line-height: 20px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; }
    .node-name { font-size: 14px; line-height: 20px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .loading-item { display: flex; align-items: center; gap: 8px; padding: 8px; font-size: 12px; color: #666; }
  `]
})
export class TreeNodeComponent {
  @Input() node!: TreeNode;
  @Input() selectedId: number | null = null;
  @Output() nodeToggle = new EventEmitter<TreeNode>();
  @Output() nodeSelect = new EventEmitter<TreeNode>();

  get hasChildren(): boolean { return this.node.type === 'category' || this.node.type === 'course' || this.node.type === 'folder'; }
  get isSelected(): boolean { return this.selectedId === this.node.id; }
  get icon(): string {
    const type = this.node.type, ext = this.node.extension.toLowerCase();
    if (type === 'category') return 'category';
    if (type === 'course') return 'school';
    if (type === 'folder') return 'folder';
    if (['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.webm'].includes(ext)) return 'play_circle_outline';
    if (['.mp3', '.wav', '.ogg', '.m4a'].includes(ext)) return 'audiotrack';
    if (ext === '.pdf') return 'picture_as_pdf';
    if (['.doc', '.docx'].includes(ext)) return 'description';
    if (['.txt', '.md'].includes(ext)) return 'article';
    if (['.jpg', '.jpeg', '.png', '.gif'].includes(ext)) return 'image';
    if (ext === '.epub') return 'menu_book';
    return 'insert_drive_file';
  }
  get iconColor(): string {
    const type = this.node.type, ext = this.node.extension.toLowerCase();
    if (type === 'category') return '#ff6f00';
    if (type === 'course') return '#1976d2';
    if (type === 'folder') return '#ffa726';
    if (['.mp4', '.avi', '.mkv'].includes(ext)) return '#e53935';
    if (['.mp3', '.wav'].includes(ext)) return '#5e35b1';
    if (ext === '.pdf') return '#d32f2f';
    if (['.doc', '.docx'].includes(ext)) return '#1976d2';
    if (['.txt', '.md'].includes(ext)) return '#424242';
    if (ext === '.epub') return '#f57c00';
    return '#757575';
  }
  onToggle() { this.nodeToggle.emit(this.node); }
  onClick() { this.hasChildren ? this.onToggle() : this.nodeSelect.emit(this.node); }
  onChildToggle(node: TreeNode) { this.nodeToggle.emit(node); }
  onChildSelect(node: TreeNode) { this.nodeSelect.emit(node); }
}

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, MatIconModule, MatButtonModule, MatProgressSpinnerModule, TreeNodeComponent],
  template: `
    <div class="sidebar">
      <h3>Categories</h3>
      @if (loading) {
        <div class="loading"><mat-spinner diameter="40"></mat-spinner><p>Loading categories...</p></div>
      }
      @if (error) {
        <div class="error-message"><mat-icon>error</mat-icon><p>{{ error }}</p><button mat-raised-button color="primary" (click)="loadCategories()">Retry</button></div>
      }
      @if (!loading && !error && categories.length === 0) {
        <div class="empty-state"><mat-icon>category</mat-icon><p>No categories found</p><p class="hint">Use Admin panel to scan courses</p></div>
      }
      @if (!loading && !error && categories.length > 0) {
        <div class="tree-container">
          @for (category of categories; track category.id) {
            <app-tree-node [node]="category" [selectedId]="selectedItemId" (nodeToggle)="toggleNode($event)" (nodeSelect)="selectFile($event)"></app-tree-node>
          }
        </div>
      }
    </div>
  `,
  styles: [`
    .sidebar { width: 100%; height: 100%; background: #f5f5f5; overflow-y: auto; padding: 16px; box-sizing: border-box; }
    h3 { margin: 0 0 16px 0; color: #333; font-size: 18px; font-weight: 500; }
    .loading, .error-message, .empty-state { text-align: center; padding: 24px; color: #666; }
    .loading mat-spinner { margin: 0 auto 16px; }
    .error-message { background: #ffebee; border-radius: 8px; padding: 16px; }
    .error-message mat-icon { color: #c62828; font-size: 48px; width: 48px; height: 48px; margin-bottom: 8px; }
    .error-message button { margin-top: 12px; }
    .empty-state mat-icon { font-size: 64px; width: 64px; height: 64px; color: #ccc; }
    .empty-state .hint { font-size: 12px; color: #999; margin-top: 8px; }
    .tree-container { width: 100%; }
  `]
})
export class SidebarComponent implements OnInit {
  @Output() fileSelected = new EventEmitter<CourseItem>();
  categories: TreeNode[] = [];
  loading = false;
  error = '';
  selectedItemId: number | null = null;
  loadedNodes = new Set<string>();

  constructor(private courseService: CourseService, private cdr: ChangeDetectorRef) {}

  ngOnInit() { this.loadCategories(); }

  loadCategories() {
    this.loading = true;
    this.error = '';
    this.courseService.getCategories().subscribe({
      next: (categories) => {
        this.categories = categories.map(cat => ({ id: cat.id, name: cat.name, path: cat.path, type: 'category', extension: '', size: 0, children: [], expanded: false, level: 0 }));
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (err) => { this.loading = false; this.error = err.message; this.cdr.detectChanges(); }
    });
  }

  toggleNode(node: TreeNode) {
    node.expanded = !node.expanded;
    const nodeKey = `${node.type}-${node.id}`;
    if (node.expanded && !this.loadedNodes.has(nodeKey)) {
      if (node.type === 'category') this.loadCourses(node);
      else if (node.type === 'course') this.loadCourseItems(node);
      else if (node.type === 'folder') this.loadFolderContents(node);
    }
    this.cdr.detectChanges();
  }

  loadCourses(categoryNode: TreeNode) {
    const nodeKey = `category-${categoryNode.id}`;
    if (this.loadedNodes.has(nodeKey)) return;
    categoryNode.loading = true;
    this.cdr.detectChanges();
    this.courseService.getCoursesByCategory(categoryNode.id).subscribe({
      next: (courses) => {
        categoryNode.children = courses.map(course => ({ id: course.id, courseId: course.id, name: course.name, path: course.path, type: 'course', extension: '', size: 0, children: [], expanded: false, level: (categoryNode.level || 0) + 1 }));
        categoryNode.loading = false;
        this.loadedNodes.add(nodeKey);
        this.cdr.detectChanges();
      },
      error: (err) => { console.error('Failed to load courses:', err); categoryNode.loading = false; this.cdr.detectChanges(); }
    });
  }

  loadCourseItems(courseNode: TreeNode) {
    const nodeKey = `course-${courseNode.id}`;
    if (this.loadedNodes.has(nodeKey) || !courseNode.courseId) return;
    courseNode.loading = true;
    this.cdr.detectChanges();
    this.courseService.getCourseItems(courseNode.courseId).subscribe({
      next: (items) => {
        courseNode.children = items.map(item => ({ id: item.id, courseId: item.courseId, name: item.name, path: item.path, type: item.type, extension: item.extension, size: item.size, children: [], expanded: false, level: (courseNode.level || 0) + 1 }));
        courseNode.loading = false;
        this.loadedNodes.add(nodeKey);
        this.cdr.detectChanges();
      },
      error: (err) => { console.error('Failed to load course items:', err); courseNode.loading = false; this.cdr.detectChanges(); }
    });
  }

  loadFolderContents(folderNode: TreeNode) {
    const nodeKey = `folder-${folderNode.id}`;
    if (this.loadedNodes.has(nodeKey)) return;
    folderNode.loading = true;
    this.cdr.detectChanges();
    this.courseService.getFolderContents(folderNode.id).subscribe({
      next: (children) => {
        folderNode.children = children.map(child => ({ id: child.id, courseId: child.courseId, name: child.name, path: child.path, type: child.type, extension: child.extension, size: child.size, children: [], expanded: false, level: (folderNode.level || 0) + 1 }));
        folderNode.loading = false;
        this.loadedNodes.add(nodeKey);
        this.cdr.detectChanges();
      },
      error: (err) => { console.error('Failed to load folder contents:', err); folderNode.loading = false; this.cdr.detectChanges(); }
    });
  }

  selectFile(node: TreeNode) {
    if (node.type !== 'folder' && node.type !== 'course' && node.type !== 'category') {
      this.selectedItemId = node.id;
      this.fileSelected.emit(node as CourseItem);
      this.cdr.detectChanges();
    }
  }

  async expandToItem(searchResult: SearchResult) {
    console.log('Expanding to item:', searchResult);
    const category = this.categories.find(c => c.name === searchResult.categoryName);
    if (!category) { console.warn('Category not found:', searchResult.categoryName); return; }
    if (!category.expanded) await this.expandNodeAsync(category);
    const course = category.children?.find(c => c.id === searchResult.courseId);
    if (!course) { console.warn('Course not found:', searchResult.courseId); return; }
    if (!course.expanded) await this.expandNodeAsync(course);
    if (searchResult.parentId) await this.expandToFolder(course, searchResult.parentId);
    this.selectedItemId = searchResult.id;
    const item: CourseItem = { id: searchResult.id, courseId: searchResult.courseId, name: searchResult.name, path: searchResult.path, type: searchResult.type, extension: searchResult.extension, size: searchResult.size, parentId: searchResult.parentId };
    this.fileSelected.emit(item);
    this.cdr.detectChanges();
  }

  private expandNodeAsync(node: TreeNode): Promise<void> {
    return new Promise((resolve) => {
      node.expanded = true;
      const nodeKey = `${node.type}-${node.id}`;
      if (this.loadedNodes.has(nodeKey)) { resolve(); return; }
      if (node.type === 'category') {
        this.courseService.getCoursesByCategory(node.id).subscribe({
          next: (courses) => { node.children = courses.map(c => ({ id: c.id, courseId: c.id, name: c.name, path: c.path, type: 'course', extension: '', size: 0, children: [], expanded: false, level: (node.level || 0) + 1 })); node.loading = false; this.loadedNodes.add(nodeKey); this.cdr.detectChanges(); resolve(); },
          error: () => { node.loading = false; this.cdr.detectChanges(); resolve(); }
        });
      } else if (node.type === 'course') {
        this.courseService.getCourseItems(node.courseId!).subscribe({
          next: (items) => { node.children = items.map(i => ({ id: i.id, courseId: i.courseId, name: i.name, path: i.path, type: i.type, extension: i.extension, size: i.size, children: [], expanded: false, level: (node.level || 0) + 1 })); node.loading = false; this.loadedNodes.add(nodeKey); this.cdr.detectChanges(); resolve(); },
          error: () => { node.loading = false; this.cdr.detectChanges(); resolve(); }
        });
      } else if (node.type === 'folder') {
        this.courseService.getFolderContents(node.id).subscribe({
          next: (children) => { node.children = children.map(c => ({ id: c.id, courseId: c.courseId, name: c.name, path: c.path, type: c.type, extension: c.extension, size: c.size, children: [], expanded: false, level: (node.level || 0) + 1 })); node.loading = false; this.loadedNodes.add(nodeKey); this.cdr.detectChanges(); resolve(); },
          error: () => { node.loading = false; this.cdr.detectChanges(); resolve(); }
        });
      } else resolve();
    });
  }

  private async expandToFolder(parentNode: TreeNode, folderId: number): Promise<void> {
    const folder = this.findNodeById(parentNode.children || [], folderId);
    if (folder && folder.type === 'folder') await this.expandNodeAsync(folder);
  }

  private findNodeById(nodes: TreeNode[], id: number): TreeNode | undefined {
    for (const node of nodes) {
      if (node.id === id) return node;
      if (node.children) {
        const found = this.findNodeById(node.children, id);
        if (found) return found;
      }
    }
    return undefined;
  }
}
