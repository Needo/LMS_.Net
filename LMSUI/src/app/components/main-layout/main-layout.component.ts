import { Component, NgZone, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../header/header.component';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { ViewerComponent } from '../viewer/viewer.component';
import { SearchResultsComponent } from '../search-results/search-results.component';
import { CourseItem } from '../../models/course.model';
import { SearchService, SearchResult } from '../../services/search.service';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-main-layout',
  standalone: true,
  imports: [
    CommonModule, 
    HeaderComponent, 
    SidebarComponent, 
    ViewerComponent,
    SearchResultsComponent
  ],
  template: `
    <div class="app-container" [class.resizing]="isResizing">
      <app-header (search)="onSearch($event)"></app-header>
      <div class="content-container">
        <div class="sidebar-wrapper" [style.width.px]="sidebarWidth">
          <app-sidebar 
            #sidebar
            (fileSelected)="onFileSelected($event)">
          </app-sidebar>
        </div>
        <div class="divider" 
             (mousedown)="startResize($event)"
             [class.dragging]="isResizing">
        </div>
        <div class="viewer-wrapper">
          @if (showSearchResults) {
            <app-search-results 
              [results]="searchResults"
              (itemSelected)="navigateToItem($event)"
              (close)="closeSearch()">
            </app-search-results>
          } @else {
            <app-viewer [selectedItem]="selectedItem"></app-viewer>
          }
        </div>
      </div>
    </div>
  `,
  styles: [`
    .app-container {
      display: flex;
      flex-direction: column;
      height: 100vh;
      overflow: hidden;
    }

    .content-container {
      display: flex;
      flex: 1;
      overflow: hidden;
      min-height: 0;
      position: relative;
    }

    .sidebar-wrapper {
      height: 100%;
      overflow: hidden;
      background: #f5f5f5;
      border-right: 1px solid #ddd;
      flex-shrink: 0;
      min-width: 200px;
      max-width: 600px;
    }

    .sidebar-wrapper app-sidebar {
      display: block;
      height: 100%;
      width: 100%;
    }

    .divider {
      width: 6px;
      background: #ccc;
      cursor: col-resize;
      flex-shrink: 0;
      position: relative;
      z-index: 10;
      transition: background 0.2s;
    }

    .divider:hover {
      background: #999;
    }

    .divider.dragging {
      background: #666;
    }

    .divider::before {
      content: '';
      position: absolute;
      left: 2px;
      top: 50%;
      transform: translateY(-50%);
      width: 2px;
      height: 40px;
      background: rgba(255, 255, 255, 0.5);
      border-radius: 1px;
    }

    .viewer-wrapper {
      flex: 1;
      display: flex;
      flex-direction: column;
      height: 100%;
      overflow: hidden;
      min-width: 0;
    }

    .viewer-wrapper app-viewer,
    .viewer-wrapper app-search-results {
      flex: 1;
      display: flex;
      flex-direction: column;
      width: 100%;
      height: 100%;
    }

    .app-container.resizing {
      user-select: none;
      cursor: col-resize;
    }

    .app-container.resizing * {
      cursor: col-resize !important;
    }
  `]
})
export class MainLayoutComponent {
  @ViewChild('sidebar') sidebarComponent!: SidebarComponent;
  
  selectedItem: CourseItem | null = null;
  sidebarWidth = 300;
  isResizing = false;
  
  // Search properties
  searchResults: SearchResult[] = [];
  showSearchResults = false;

  constructor(
    private ngZone: NgZone,
    private searchService: SearchService,
    private authService: AuthService
  ) {}

  onFileSelected(item: CourseItem) {
    this.selectedItem = item;
    this.showSearchResults = false; // Close search when file selected from tree
  }

  onSearch(query: string) {
    if (!query || query.trim() === '') {
      this.closeSearch();
      return;
    }

    const userId = this.authService.currentUser?.id;
    
    this.searchService.search(query, userId).subscribe({
      next: (results) => {
        this.searchResults = results;
        this.showSearchResults = true;
      },
      error: (error) => {
        console.error('Search error:', error);
        this.searchResults = [];
        this.showSearchResults = true;
      }
    });
  }

  closeSearch() {
    this.showSearchResults = false;
    this.searchResults = [];
  }

  navigateToItem(result: SearchResult) {
    console.log('Navigate to item:', result);
    
    // Close search results
    this.closeSearch();
    
    // Tell sidebar to expand to this item
    if (this.sidebarComponent) {
      //this.sidebarComponent.expandToItem(result);
    }
  }

  startResize(event: MouseEvent) {
    event.preventDefault();
    this.isResizing = true;
    
    const startX = event.clientX;
    const startWidth = this.sidebarWidth;

    this.ngZone.runOutsideAngular(() => {
      const onMouseMove = (moveEvent: MouseEvent) => {
        const delta = moveEvent.clientX - startX;
        const newWidth = startWidth + delta;
        const constrainedWidth = Math.min(600, Math.max(200, newWidth));
        
        const sidebarElement = document.querySelector('.sidebar-wrapper') as HTMLElement;
        if (sidebarElement) {
          sidebarElement.style.width = `${constrainedWidth}px`;
        }
        
        this.sidebarWidth = constrainedWidth;
      };

      const onMouseUp = () => {
        this.ngZone.run(() => {
          this.isResizing = false;
        });

        document.removeEventListener('mousemove', onMouseMove);
        document.removeEventListener('mouseup', onMouseUp);
      };

      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup', onMouseUp);
    });
  }
}
