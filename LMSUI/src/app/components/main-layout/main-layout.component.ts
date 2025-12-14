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
