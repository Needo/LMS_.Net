import { ChangeDetectorRef, Component, Input, OnChanges, SimpleChanges, ViewChild, ElementRef, AfterViewInit, OnDestroy, ChangeDetectionStrategy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { CourseItem } from '../../models/course.model';
import { CourseService } from '../../services/course.service';
import { PdfViewerComponent } from '../pdf-viewer/pdf-viewer.component';
import ePub from 'epubjs';

@Component({
  selector: 'app-viewer',
  standalone: true,
  imports: [CommonModule, MatIconModule, MatButtonModule, PdfViewerComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="viewer">
      @if (!selectedItem) {
        <div class="placeholder">
          <mat-icon>description</mat-icon>
          <p>Select a file to view</p>
        </div>
      }
      @if (selectedItem) {
        <div class="content">
          <div class="file-header">
            <h2>{{ selectedItem.name }}</h2>
            <!-- EPUB navigation controls -->
            @if (selectedItem.type === 'ebook' && epubRendition) {
              <div class="epub-controls">
                <button mat-icon-button (click)="epubPrev()" [disabled]="!canGoPrev">
                  <mat-icon>chevron_left</mat-icon>
                </button>
                <span class="page-info">{{ epubPageInfo }}</span>
                <button mat-icon-button (click)="epubNext()" [disabled]="!canGoNext">
                  <mat-icon>chevron_right</mat-icon>
                </button>
              </div>
            }
          </div>
          
          @if (selectedItem.type === 'video') {
            <div class="media-container">
              <video controls [src]="fileUrl" class="video-player"></video>
            </div>
          }
          
          @if (selectedItem.type === 'audio') {
            <div class="audio-container">
              <audio controls [src]="fileUrl" class="audio-player"></audio>
            </div>
          }
          
          @if (selectedItem.type === 'document' && selectedItem.extension === '.pdf') {
            <app-pdf-viewer [pdfUrl]="fileUrl"></app-pdf-viewer>
          }
          
          @if (selectedItem.type === 'document' && selectedItem.extension === '.txt') {
            <div class="text-viewer">
              <pre class="text-content">{{ textContent }}</pre>
            </div>
          }
          
          @if (selectedItem.type === 'document' && selectedItem.extension === '.html') {
            <iframe [src]="sanitizedFileUrl" class="document-viewer"></iframe>
          }
          
          <!-- EPUB viewer -->
          @if (selectedItem.type === 'ebook') {
            <div class="epub-container">
              <div #epubViewer class="epub-viewer"></div>
            </div>
          }
          
          @if (
            selectedItem.type === 'document' &&
            !['.pdf', '.txt', '.html'].includes(selectedItem.extension) ||
            selectedItem.type === 'file'
          ) {
            <div class="file-info">
              <mat-icon class="large-icon">insert_drive_file</mat-icon>
              <p>{{ selectedItem.name }}</p>
              <p>Size: {{ formatSize(selectedItem.size) }}</p>
              <a [href]="fileUrl" download mat-raised-button color="primary">
                <mat-icon>download</mat-icon>
                Download
              </a>
            </div>
          }
        </div>
      }
    </div>
  `,
  styles: [`
    .viewer {
      flex: 1;
      display: flex;
      flex-direction: column;
      height: 100%;
      overflow: hidden;
      background: white;
    }

    .placeholder {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100%;
      color: #999;
    }

    .placeholder mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
    }

    .content {
      flex: 1;
      display: flex;
      flex-direction: column;
      height: 100%;
      overflow: hidden;
    }

    .error-state {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 48px;
      color: #c62828;
    }

    .error-state mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
    }

    .file-header {
      padding: 16px 24px;
      border-bottom: 1px solid #e0e0e0;
      flex-shrink: 0;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .file-header h2 {
      margin: 0;
      font-size: 18px;
      font-weight: 500;
    }

    .epub-controls {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .page-info {
      font-size: 14px;
      color: #666;
      min-width: 120px;
      text-align: center;
    }

    .media-container {
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #000;
      overflow: hidden;
    }

    .video-player {
      width: 100%;
      height: 100%;
      max-width: 100%;
      max-height: 100%;
      object-fit: contain;
    }

    .audio-container {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 48px;
    }

    .audio-player {
      width: 100%;
      max-width: 600px;
    }

    .document-viewer {
      flex: 1;
      width: 100%;
      height: 100%;
      border: none;
      background: white;
    }

    .text-viewer {
      flex: 1;
      overflow: auto;
      background: #fafafa;
      padding: 24px;
    }

    .text-content {
      font-family: 'Courier New', monospace;
      font-size: 14px;
      line-height: 1.6;
      white-space: pre-wrap;
      word-wrap: break-word;
      margin: 0;
      background: white;
      padding: 16px;
      border-radius: 4px;
      border: 1px solid #e0e0e0;
    }

    .epub-container {
      flex: 1;
      overflow: hidden;
      background: #f5f5f5;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }

    .epub-viewer {
      width: 100%;
      height: 100%;
      max-width: 900px;
      background: white;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      border-radius: 4px;
    }

    .file-info {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 48px;
      text-align: center;
    }

    .large-icon {
      font-size: 96px;
      width: 96px;
      height: 96px;
      margin-bottom: 24px;
      color: #757575;
    }
  `]
})
export class ViewerComponent implements OnChanges, AfterViewInit, OnDestroy {
  @Input() selectedItem: CourseItem | null = null;
  @ViewChild('epubViewer') epubViewerRef?: ElementRef;
  
  fileUrl: string = '';
  sanitizedFileUrl: SafeResourceUrl | null = null;
  textContent: string = '';
  private previousItemId: number | null = null;

  // EPUB properties
  epubBook: any = null;
  epubRendition: any = null;
  epubPageInfo: string = '';
  canGoPrev: boolean = false;
  canGoNext: boolean = true;

  constructor(
    private courseService: CourseService,
    private sanitizer: DomSanitizer,
    private cdr: ChangeDetectorRef
  ) {}

  ngAfterViewInit() {
    // Component ready
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes['selectedItem']) {
      const currentItem = changes['selectedItem'].currentValue;
      
      // Only process if it's actually a new file (not folder/course/category)
      if (currentItem) {
        // Ignore folders, courses, and categories - don't reload viewer
        if (currentItem.type === 'folder' || 
            currentItem.type === 'course' || 
            currentItem.type === 'category') {
          return; // Do nothing - keep current viewer content
        }
        
        // Only reload if it's a different file
        if (currentItem.id !== this.previousItemId) {
          this.previousItemId = currentItem.id;
          this.textContent = '';
          this.fileUrl = '';
          this.sanitizedFileUrl = null;
          this.cleanupEpub();
          this.cdr.detectChanges();
          this.loadContent();
        }
      } else if (!currentItem) {
        // Clear viewer when nothing is selected
        this.fileUrl = '';
        this.sanitizedFileUrl = null;
        this.textContent = '';
        this.previousItemId = null;
        this.cleanupEpub();
      }
    }
  }

  private loadContent() {
    if (!this.selectedItem) return;

    try {
      this.fileUrl = this.courseService.getFileUrl(this.selectedItem.path);
      console.log('Loading file URL:', this.fileUrl);
      
      if (this.fileUrl && this.fileUrl.startsWith('http')) {
        this.sanitizedFileUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.fileUrl);
        console.log('Sanitized URL created successfully');
      } else {
        console.error('Invalid file URL:', this.fileUrl);
        this.sanitizedFileUrl = null;
      }
      
      this.cdr.detectChanges();
    } catch (error) {
      console.error('Error in loadContent:', error);
      this.sanitizedFileUrl = null;
      this.cdr.detectChanges();
    }

    if (this.selectedItem.extension === '.txt') {
      fetch(this.fileUrl)
        .then(res => res.text())
        .then(text => {
          this.textContent = text;
          this.cdr.detectChanges();
        })
        .catch(err => {
          console.error('Failed to load text file', err);
          this.textContent = 'Error loading file';
          this.cdr.detectChanges();
        });
    } else if (this.selectedItem.type === 'ebook') {
      setTimeout(() => this.loadEpubBook(), 200);
    }
  }

  private loadEpubBook() {
    if (!this.epubViewerRef?.nativeElement) {
      console.error('EPUB viewer element not ready');
      return;
    }

    try {
      console.log('Loading EPUB from:', this.fileUrl);
      
      this.epubBook = ePub(this.fileUrl);
      
      this.epubRendition = this.epubBook.renderTo(this.epubViewerRef.nativeElement, {
        width: '100%',
        height: '100%',
        flow: 'paginated',
        spread: 'none'
      });

      this.epubRendition.display().then(() => {
        console.log('EPUB displayed successfully');
        this.cdr.detectChanges();
      });

      this.epubRendition.on('relocated', (location: any) => {
        if (location?.start?.displayed) {
          const current = location.start.displayed.page;
          const total = location.start.displayed.total;
          this.epubPageInfo = `Page ${current} of ${total}`;
          this.canGoPrev = !location.atStart;
          this.canGoNext = !location.atEnd;
          this.cdr.detectChanges();
        }
      });

    } catch (error) {
      console.error('Error loading EPUB:', error);
    }
  }

  epubPrev() {
    if (this.epubRendition) {
      this.epubRendition.prev();
    }
  }

  epubNext() {
    if (this.epubRendition) {
      this.epubRendition.next();
    }
  }

  private cleanupEpub() {
    if (this.epubRendition) {
      this.epubRendition.destroy();
      this.epubRendition = null;
    }
    if (this.epubBook) {
      this.epubBook.destroy();
      this.epubBook = null;
    }
    this.epubPageInfo = '';
  }

  sanitizeUrl(url: string): SafeResourceUrl {
    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  }

  formatSize(bytes: number): string {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1048576) return (bytes / 1024).toFixed(2) + ' KB';
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(2) + ' MB';
    return (bytes / 1073741824).toFixed(2) + ' GB';
  }

  ngOnDestroy() {
    this.cleanupEpub();
  }
}
