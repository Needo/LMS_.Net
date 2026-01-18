import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatTableModule } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { SearchResult } from '../../services/search.service';

@Component({
  selector: 'app-search-results',
  standalone: true,
  imports: [CommonModule, MatTableModule, MatButtonModule, MatIconModule],
  template: `
    <div class="search-results-container">
      <div class="header">
        <div class="title-section">
          <mat-icon>search</mat-icon>
          <h2>Search Results</h2>
          <span class="count">({{ results.length }} items found)</span>
        </div>
        <button mat-icon-button (click)="onClose()">
          <mat-icon>close</mat-icon>
        </button>
      </div>

      @if (results.length === 0) {
        <div class="empty-state">
          <mat-icon>search_off</mat-icon>
          <p>No results found</p>
          <p class="hint">Try different search terms</p>
        </div>
      }

      @if (results.length > 0) {
        <table mat-table [dataSource]="results" class="results-table">
          <ng-container matColumnDef="icon">
            <th mat-header-cell *matHeaderCellDef></th>
            <td mat-cell *matCellDef="let result">
              <mat-icon [style.color]="getIconColor(result)">{{ getIcon(result) }}</mat-icon>
            </td>
          </ng-container>

          <ng-container matColumnDef="name">
            <th mat-header-cell *matHeaderCellDef>Name</th>
            <td mat-cell *matCellDef="let result">{{ result.name }}</td>
          </ng-container>

          <ng-container matColumnDef="course">
            <th mat-header-cell *matHeaderCellDef>Course</th>
            <td mat-cell *matCellDef="let result">{{ result.courseName }}</td>
          </ng-container>

          <ng-container matColumnDef="category">
            <th mat-header-cell *matHeaderCellDef>Category</th>
            <td mat-cell *matCellDef="let result">{{ result.categoryName }}</td>
          </ng-container>

          <ng-container matColumnDef="type">
            <th mat-header-cell *matHeaderCellDef>Type</th>
            <td mat-cell *matCellDef="let result">
              <span class="type-badge" [class]="result.type">{{ result.type }}</span>
            </td>
          </ng-container>

          <ng-container matColumnDef="size">
            <th mat-header-cell *matHeaderCellDef>Size</th>
            <td mat-cell *matCellDef="let result">{{ formatSize(result.size) }}</td>
          </ng-container>

          <ng-container matColumnDef="actions">
            <th mat-header-cell *matHeaderCellDef>Actions</th>
            <td mat-cell *matCellDef="let result">
              <button mat-icon-button (click)="onItemSelected(result)" matTooltip="Open in tree">
                <mat-icon>arrow_forward</mat-icon>
              </button>
            </td>
          </ng-container>

          <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
          <tr mat-row *matRowDef="let row; columns: displayedColumns;" 
              class="clickable-row"
              (click)="onItemSelected(row)"></tr>
        </table>
      }
    </div>
  `,
  styles: [`
    .search-results-container {
      display: flex;
      flex-direction: column;
      height: 100%;
      background: white;
      overflow: hidden;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px 24px;
      border-bottom: 2px solid #e0e0e0;
      background: #f5f5f5;
    }

    .title-section {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .title-section mat-icon {
      font-size: 28px;
      width: 28px;
      height: 28px;
      color: #1976d2;
    }

    .header h2 {
      margin: 0;
      font-size: 20px;
      font-weight: 500;
      color: #333;
    }

    .count {
      font-size: 14px;
      color: #666;
    }

    .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      flex: 1;
      padding: 48px;
      color: #999;
    }

    .empty-state mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
      color: #ccc;
    }

    .empty-state .hint {
      font-size: 13px;
      color: #bbb;
    }

    .results-table {
      width: 100%;
      flex: 1;
      overflow: auto;
    }

    .clickable-row {
      cursor: pointer;
      transition: background 0.2s;
    }

    .clickable-row:hover {
      background: #f5f5f5;
    }

    .mat-column-icon {
      width: 48px;
      padding-left: 16px;
    }

    .mat-column-type {
      width: 100px;
    }

    .mat-column-size {
      width: 100px;
    }

    .mat-column-actions {
      width: 80px;
      text-align: center;
    }

    .type-badge {
      display: inline-block;
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 11px;
      font-weight: 500;
      text-transform: uppercase;
    }

    .type-badge.video {
      background: #ffebee;
      color: #c62828;
    }

    .type-badge.audio {
      background: #f3e5f5;
      color: #6a1b9a;
    }

    .type-badge.document {
      background: #e3f2fd;
      color: #1565c0;
    }

    .type-badge.ebook {
      background: #fff3e0;
      color: #e65100;
    }

    .type-badge.image {
      background: #e8f5e9;
      color: #2e7d32;
    }

    .type-badge.folder {
      background: #fff9c4;
      color: #f57f17;
    }
  `]
})
export class SearchResultsComponent {
  @Input() results: SearchResult[] = [];
  @Output() itemSelected = new EventEmitter<SearchResult>();
  @Output() close = new EventEmitter<void>();

  displayedColumns = ['icon', 'name', 'course', 'category', 'type', 'size', 'actions'];

  onItemSelected(result: SearchResult) {
    this.itemSelected.emit(result);
  }

  onClose() {
    this.close.emit();
  }

  getIcon(result: SearchResult): string {
    const ext = result.extension.toLowerCase();
    const type = result.type;

    if (type === 'folder') return 'folder';
    if (type === 'video' || ['.mp4', '.avi', '.mkv'].includes(ext)) return 'play_circle_outline';
    if (type === 'audio' || ['.mp3', '.wav'].includes(ext)) return 'audiotrack';
    if (ext === '.pdf') return 'picture_as_pdf';
    if (type === 'ebook' || ext === '.epub') return 'menu_book';
    if (type === 'image' || ['.jpg', '.png', '.gif'].includes(ext)) return 'image';
    if (type === 'document') return 'description';
    return 'insert_drive_file';
  }

  getIconColor(result: SearchResult): string {
    const type = result.type;
    
    if (type === 'folder') return '#ffa726';
    if (type === 'video') return '#e53935';
    if (type === 'audio') return '#5e35b1';
    if (type === 'document') return '#1976d2';
    if (type === 'ebook') return '#f57c00';
    if (type === 'image') return '#43a047';
    return '#757575';
  }

  formatSize(bytes: number): string {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + ' MB';
    return (bytes / 1073741824).toFixed(1) + ' GB';
  }
}
