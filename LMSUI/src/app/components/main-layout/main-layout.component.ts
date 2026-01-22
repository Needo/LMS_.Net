import { Component, NgZone, ViewChild, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../header/header.component';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { ViewerComponent } from '../viewer/viewer.component';
import { SearchResultsComponent } from '../search-results/search-results.component';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
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
    SearchResultsComponent,
    MatButtonModule,
    MatIconModule
  ],
  template: `
    <div class="app-container" [class.resizing]="isResizing">
      <app-header 
        (search)="onSearch($event)"
        (searchingChange)="onSearchingChange($event)"
        #header>
      </app-header>
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
          @if (isResizing) {
            <div class="resize-overlay"></div>
          }
          @if (showSearchResults && !isViewingSearchItem) {
            <app-search-results 
              [results]="searchResults"
              (itemSelected)="navigateToItem($event)"
              (close)="closeSearch()">
            </app-search-results>
          } @else if (isViewingSearchItem) {
            <div class="viewer-with-back">
              <div class="back-bar">
                <button mat-raised-button color="primary" (click)="goBackToResults()">
                  <mat-icon>arrow_back</mat-icon>
                  Back to Search Results
                </button>
              </div>
              <app-viewer [selectedItem]="selectedItem"></app-viewer>
            </div>
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
      background: linear-gradient(180deg, #f8f9fa 0%, #ffffff 100%);
      border-right: 1px solid #e0e0e0;
      flex-shrink: 0;
      min-width: 200px;
      max-width: 600px;
      box-shadow: 2px 0 8px rgba(0, 0, 0, 0.05);
    }

    .sidebar-wrapper app-sidebar {
      display: block;
      height: 100%;
      width: 100%;
    }

    .divider {
      width: 6px;
      background: linear-gradient(180deg, #e0e0e0 0%, #bdbdbd 100%);
      cursor: col-resize;
      flex-shrink: 0;
      position: relative;
      z-index: 10;
      transition: all 0.2s ease;
    }

    .divider:hover {
      background: linear-gradient(180deg, #667eea 0%, #764ba2 100%);
      width: 8px;
    }

    .divider.dragging {
      background: linear-gradient(180deg, #667eea 0%, #764ba2 100%);
      width: 8px;
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
      position: relative;
    }

    .resize-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      z-index: 1000;
      background: transparent;
    }

    .viewer-wrapper app-viewer,
    .viewer-wrapper app-search-results {
      flex: 1;
      display: flex;
      flex-direction: column;
      width: 100%;
      height: 100%;
    }

    .viewer-with-back {
      flex: 1;
      display: flex;
      flex-direction: column;
      width: 100%;
      height: 100%;
    }

    .back-bar {
      padding: 16px 24px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      border-bottom: 1px solid rgba(0, 0, 0, 0.1);
      flex-shrink: 0;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }

    .back-bar button {
      color: white;
      border-color: rgba(255, 255, 255, 0.3);
      background: rgba(255, 255, 255, 0.1);
    }

    .back-bar button:hover {
      background: rgba(255, 255, 255, 0.2);
    }

    .viewer-with-back app-viewer {
      flex: 1;
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
  @ViewChild('header') headerComponent!: HeaderComponent;
  
  selectedItem: CourseItem | null = null;
  sidebarWidth = 300;
  isResizing = false;
  
  searchResults: SearchResult[] = [];
  showSearchResults = false;
  isViewingSearchItem = false;

  constructor(
    private ngZone: NgZone,
    private searchService: SearchService,
    private authService: AuthService
  ) {}

  @HostListener('document:mouseup')
  onDocumentMouseUp() {
    if (this.isResizing) {
      this.isResizing = false;
    }
  }

  onFileSelected(item: CourseItem) {
    this.selectedItem = item;
    if (!this.isViewingSearchItem) {
      this.showSearchResults = false;
    }
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
        this.isViewingSearchItem = false;
        if (this.headerComponent) {
          this.headerComponent.stopSearching();
        }
      },
      error: (error) => {
        console.error('Search error:', error);
        this.searchResults = [];
        this.showSearchResults = true;
        if (this.headerComponent) {
          this.headerComponent.stopSearching();
        }
      }
    });
  }

  onSearchingChange(searching: boolean) {
    // Handle searching state if needed
  }

  closeSearch() {
    this.showSearchResults = false;
    this.searchResults = [];
    this.isViewingSearchItem = false;
  }

  navigateToItem(result: SearchResult) {
    console.log('Navigate to item:', result);
    this.isViewingSearchItem = true;
    
    if (this.sidebarComponent) {
      this.sidebarComponent.expandToItem(result);
    }
  }

  goBackToResults() {
    this.isViewingSearchItem = false;
  }

  startResize(event: MouseEvent) {
    event.preventDefault();
    this.isResizing = true;
    
    const startX = event.clientX;
    const startWidth = this.sidebarWidth;

    const onMouseMove = (moveEvent: MouseEvent) => {
      const delta = moveEvent.clientX - startX;
      const newWidth = startWidth + delta;
      this.sidebarWidth = Math.min(600, Math.max(200, newWidth));
    };

    const onMouseUp = () => {
      this.isResizing = false;
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
    };

    document.addEventListener('mousemove', onMouseMove);
    document.addEventListener('mouseup', onMouseUp);
  }
}
