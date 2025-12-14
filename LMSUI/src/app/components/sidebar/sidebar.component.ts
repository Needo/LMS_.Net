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
