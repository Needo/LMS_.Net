import { Component, Input, OnInit, OnDestroy, ViewChild, ElementRef, ChangeDetectorRef, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import * as pdfjsLib from 'pdfjs-dist';

@Component({
  selector: 'app-pdf-viewer',
  standalone: true,
  imports: [CommonModule, MatIconModule, MatButtonModule, MatProgressSpinnerModule],
  template: `
    <div class="pdf-viewer-container">
      @if (loading) {
        <div class="loading-state">
          <mat-spinner diameter="50"></mat-spinner>
          <p>Loading PDF...</p>
        </div>
      } @else if (error) {
        <div class="error-state">
          <mat-icon>error</mat-icon>
          <p>{{ error }}</p>
        </div>
      } @else {
        <div class="pdf-toolbar">
          <button mat-icon-button (click)="toggleOutline()" [class.active]="showOutline" title="Toggle Bookmarks">
            <mat-icon>menu_book</mat-icon>
          </button>
          <button mat-icon-button (click)="previousPage()" [disabled]="currentPage <= 1">
            <mat-icon>chevron_left</mat-icon>
          </button>
          <span class="page-info">Page {{ currentPage }} / {{ totalPages }}</span>
          <button mat-icon-button (click)="nextPage()" [disabled]="currentPage >= totalPages">
            <mat-icon>chevron_right</mat-icon>
          </button>
          <div class="divider"></div>
          <button mat-icon-button (click)="zoomOut()" [disabled]="scale <= 0.5" title="Zoom Out">
            <mat-icon>zoom_out</mat-icon>
          </button>
          <span class="zoom-info">{{ (scale * 100).toFixed(0) }}%</span>
          <button mat-icon-button (click)="zoomIn()" [disabled]="scale >= 3" title="Zoom In">
            <mat-icon>zoom_in</mat-icon>
          </button>
          <div class="divider"></div>
          <button mat-icon-button (click)="resetZoom()" title="Reset Zoom (100%)">
            <mat-icon>restart_alt</mat-icon>
          </button>
          <button mat-icon-button (click)="fitToWidth()" title="Fit to Width">
            <mat-icon>width_wide</mat-icon>
          </button>
          <button mat-icon-button (click)="fitToHeight()" title="Fit to Height">
            <mat-icon>height</mat-icon>
          </button>
        </div>
        
        <div class="pdf-content">
          @if (showOutline && outline.length > 0) {
            <div class="pdf-outline">
              <div class="outline-header">
                <h3>Bookmarks</h3>
                <button mat-icon-button (click)="toggleOutline()">
                  <mat-icon>close</mat-icon>
                </button>
              </div>
              <div class="outline-items">
                @for (item of outline; track item.dest) {
                  <div class="outline-item" 
                       [style.padding-left.px]="(item.level || 0) * 16 + 16"
                       (click)="goToOutlineItem(item)">
                    {{ item.title }}
                  </div>
                }
              </div>
            </div>
          }
          
          <div class="pdf-canvas-container" #canvasContainer>
            <canvas #pdfCanvas></canvas>
          </div>
        </div>
      }
    </div>
  `,
  styles: [`
    .pdf-viewer-container {
      display: flex;
      flex-direction: column;
      width: 100%;
      height: 100%;
      background: #525659;
    }

    .loading-state, .error-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100%;
      color: white;
    }

    .error-state mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      color: #ff6b6b;
      margin-bottom: 16px;
    }

    .pdf-toolbar {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 16px;
      background: #323639;
      border-bottom: 1px solid #1a1a1a;
      flex-shrink: 0;
    }

    .pdf-toolbar button {
      color: rgba(255, 255, 255, 0.9);
    }

    .pdf-toolbar button:disabled {
      opacity: 0.3;
    }

    .pdf-toolbar button.active {
      background: rgba(255, 255, 255, 0.1);
    }

    .divider {
      width: 1px;
      height: 24px;
      background: rgba(255, 255, 255, 0.2);
      margin: 0 4px;
    }

    .page-info, .zoom-info {
      color: rgba(255, 255, 255, 0.9);
      font-size: 13px;
      padding: 0 8px;
    }

    .pdf-content {
      display: flex;
      flex: 1;
      overflow: hidden;
    }

    .pdf-outline {
      width: 250px;
      background: #3a3a3a;
      border-right: 1px solid #1a1a1a;
      display: flex;
      flex-direction: column;
      flex-shrink: 0;
    }

    .outline-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 16px;
      border-bottom: 1px solid #1a1a1a;
    }

    .outline-header h3 {
      margin: 0;
      font-size: 14px;
      font-weight: 500;
      color: rgba(255, 255, 255, 0.9);
    }

    .outline-header button {
      color: rgba(255, 255, 255, 0.7);
    }

    .outline-items {
      flex: 1;
      overflow-y: auto;
      padding: 8px 0;
    }

    .outline-item {
      padding: 8px 16px;
      color: rgba(255, 255, 255, 0.8);
      font-size: 13px;
      cursor: pointer;
      transition: background 0.2s;
    }

    .outline-item:hover {
      background: rgba(255, 255, 255, 0.1);
    }

    .pdf-canvas-container {
      flex: 1;
      overflow: auto;
      display: flex;
      justify-content: center;
      padding: 20px;
    }

    canvas {
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
      background: white;
    }
  `]
})
export class PdfViewerComponent implements OnInit, OnChanges, OnDestroy {
  @Input() pdfUrl: string = '';
  @ViewChild('pdfCanvas') canvasRef!: ElementRef<HTMLCanvasElement>;
  @ViewChild('canvasContainer') canvasContainerRef!: ElementRef<HTMLDivElement>;

  loading = true;
  error = '';
  pdfDocument: any = null;
  currentPage = 1;
  totalPages = 0;
  scale = 1.0;
  showOutline = false;
  outline: any[] = [];

  constructor(private cdr: ChangeDetectorRef) {
    pdfjsLib.GlobalWorkerOptions.workerSrc = `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js`;
  }

  ngOnInit() {
    if (this.pdfUrl) {
      this.loadPdf();
    }
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes['pdfUrl'] && !changes['pdfUrl'].firstChange) {
      this.loadPdf();
    }
  }

  ngOnDestroy() {
    if (this.pdfDocument) {
      this.pdfDocument.destroy();
    }
  }

  async loadPdf() {
    this.loading = true;
    this.error = '';
    this.cdr.detectChanges();

    try {
      const loadingTask = pdfjsLib.getDocument(this.pdfUrl);
      this.pdfDocument = await loadingTask.promise;
      this.totalPages = this.pdfDocument.numPages;
      this.currentPage = 1;
      
      try {
        const outlineData = await this.pdfDocument.getOutline();
        if (outlineData) {
          this.outline = this.flattenOutline(outlineData);
          // Auto-open bookmarks panel if bookmarks exist
          if (this.outline.length > 0) {
            this.showOutline = true;
          }
        }
      } catch (e) {
        console.log('No outline available');
      }

      this.loading = false;
      this.cdr.detectChanges();
      
      // Wait for DOM to be ready, then render at fit-to-height
      setTimeout(() => {
        this.fitToHeight();
      }, 300);
    } catch (error: any) {
      this.loading = false;
      this.error = 'Failed to load PDF: ' + error.message;
      this.cdr.detectChanges();
      console.error('PDF load error:', error);
    }
  }

  flattenOutline(outline: any[], level = 0): any[] {
    const result: any[] = [];
    for (const item of outline) {
      result.push({
        title: item.title,
        dest: item.dest,
        level: level
      });
      if (item.items && item.items.length > 0) {
        result.push(...this.flattenOutline(item.items, level + 1));
      }
    }
    return result;
  }

  async renderPage() {
    if (!this.pdfDocument || !this.canvasRef) return;

    try {
      const page = await this.pdfDocument.getPage(this.currentPage);
      const canvas = this.canvasRef.nativeElement;
      const context = canvas.getContext('2d');

      const viewport = page.getViewport({ scale: this.scale });
      canvas.width = viewport.width;
      canvas.height = viewport.height;

      const renderContext = {
        canvasContext: context,
        viewport: viewport
      };

      await page.render(renderContext).promise;
      this.cdr.detectChanges();
    } catch (error) {
      console.error('Render error:', error);
    }
  }

  previousPage() {
    if (this.currentPage > 1) {
      this.currentPage--;
      this.renderPage();
    }
  }

  nextPage() {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
      this.renderPage();
    }
  }

  zoomIn() {
    this.scale = Math.min(3, this.scale + 0.25);
    this.renderPage();
  }

  zoomOut() {
    this.scale = Math.max(0.5, this.scale - 0.25);
    this.renderPage();
  }

  fitToWidth() {
    if (!this.canvasContainerRef || !this.pdfDocument) return;
    
    this.pdfDocument.getPage(this.currentPage).then((page: any) => {
      const containerWidth = this.canvasContainerRef.nativeElement.clientWidth - 40;
      const viewport = page.getViewport({ scale: 1 });
      this.scale = containerWidth / viewport.width;
      this.renderPage();
    });
  }

  fitToHeight() {
    if (!this.canvasContainerRef || !this.pdfDocument) return;
    
    this.pdfDocument.getPage(this.currentPage).then((page: any) => {
      const containerHeight = this.canvasContainerRef.nativeElement.clientHeight - 40;
      const viewport = page.getViewport({ scale: 1 });
      this.scale = containerHeight / viewport.height;
      this.renderPage();
    });
  }

  resetZoom() {
    this.scale = 1.0;
    this.renderPage();
  }

  toggleOutline() {
    this.showOutline = !this.showOutline;
    this.cdr.detectChanges();
    // Re-render the page when panel opens/closes to adjust to new dimensions
    if (this.pdfDocument && this.canvasRef) {
      setTimeout(() => {
        this.fitToHeight();
      }, 150);
    }
  }

  async goToOutlineItem(item: any) {
    if (!this.pdfDocument || !item.dest) return;

    try {
      const dest = typeof item.dest === 'string' 
        ? await this.pdfDocument.getDestination(item.dest)
        : item.dest;
      
      if (dest) {
        const pageIndex = await this.pdfDocument.getPageIndex(dest[0]);
        this.currentPage = pageIndex + 1;
        this.renderPage();
      }
    } catch (error) {
      console.error('Navigate error:', error);
    }
  }
}
