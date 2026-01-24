import { ChangeDetectorRef, Component, Input, OnChanges, SimpleChanges, ViewChild, ElementRef, AfterViewInit, OnDestroy, ChangeDetectionStrategy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { CourseItem } from '../../models/course.model';
import { CourseService } from '../../services/course.service';
import ePub from 'epubjs';

@Component({
  selector: 'app-viewer',
  standalone: true,
  imports: [CommonModule, MatIconModule, MatButtonModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="viewer">
      @if (!selectedItem) {
        <div class="no-selection">
          <mat-icon>description</mat-icon>
          <p>Select a file to view</p>
        </div>
      } @else {
        <div class="viewer-content">
          @if (selectedItem.type === 'document' && selectedItem.extension === '.epub') {
            <div class="epub-viewer">
              <div class="epub-toolbar">
                <button mat-icon-button (click)="epubPrev()" [disabled]="!epubReady">
                  <mat-icon>chevron_left</mat-icon>
                </button>
                <span class="epub-title">{{ selectedItem.name }}</span>
                <button mat-icon-button (click)="epubNext()" [disabled]="!epubReady">
                  <mat-icon>chevron_right</mat-icon>
                </button>
              </div>
              <div #epubContainer class="epub-container"></div>
            </div>
          }
          
          @if (selectedItem.type === 'document' && selectedItem.extension === '.pdf') {
            @if (sanitizedFileUrl) {
              <iframe [src]="sanitizedFileUrl" class="document-viewer"></iframe>
            } @else {
              <div class="error-state">
                <mat-icon>error</mat-icon>
                <p>Failed to load PDF</p>
              </div>
            }
          }
          
          @if (selectedItem.type === 'document' && selectedItem.extension === '.txt') {
            <div class="text-viewer">
              <pre>{{ textContent }}</pre>
            </div>
          }
          
          @if (selectedItem.type === 'video') {
            <video controls class="video-player">
              <source [src]="fileUrl" [type]="'video/' + selectedItem.extension.substring(1)">
              Your browser does not support the video tag.
            </video>
          }
          
          @if (selectedItem.type === 'audio') {
            <div class="audio-player-container">
              <audio controls class="audio-player">
                <source [src]="fileUrl" [type]="'audio/' + selectedItem.extension.substring(1)">
                Your browser does not support the audio tag.
              </audio>
            </div>
          }
          
          @if (selectedItem.type === 'image') {
            <div class="image-viewer">
              <img [src]="fileUrl" [alt]="selectedItem.name">
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
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: #f5f5f5;
    }

    .no-selection {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: #999;
    }

    .no-selection mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
    }

    .viewer-content {
      flex: 1;
      display: flex;
      width: 100%;
      height: 100%;
      overflow: hidden;
    }

    .document-viewer {
      flex: 1;
      width: 100%;
      height: 100%;
      border: none;
      background: white;
    }

    .epub-viewer {
      flex: 1;
      display: flex;
      flex-direction: column;
      width: 100%;
      height: 100%;
      background: white;
    }

    .epub-toolbar {
      display: flex;
      align-items: center;
      padding: 8px 16px;
      background: #f5f5f5;
      border-bottom: 1px solid #ddd;
    }

    .epub-title {
      flex: 1;
      text-align: center;
      font-weight: 500;
    }

    .epub-container {
      flex: 1;
      overflow: auto;
    }

    .text-viewer {
      flex: 1;
      padding: 24px;
      overflow: auto;
      background: white;
    }

    .text-viewer pre {
      margin: 0;
      white-space: pre-wrap;
      word-wrap: break-word;
      font-family: 'Courier New', monospace;
      font-size: 14px;
      line-height: 1.6;
    }

    .video-player {
      width: 100%;
      height: 100%;
      background: black;
    }

    .audio-player-container {
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      background: white;
    }

    .audio-player {
      width: 80%;
      max-width: 600px;
    }

    .image-viewer {
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #333;
      overflow: auto;
      padding: 20px;
    }

    .image-viewer img {
      max-width: 100%;
      max-height: 100%;
      object-fit: contain;
    }

    .error-state {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: #999;
    }

    .error-state mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
      color: #ff6b6b;
    }
  `]
})
export class ViewerComponent implements OnChanges, AfterViewInit, OnDestroy {
  @Input() selectedItem: CourseItem | null = null;
  @ViewChild('epubContainer') epubContainer?: ElementRef;

  fileUrl: string = '';
  sanitizedFileUrl: SafeResourceUrl | null = null;
  textContent: string = '';
  epubReady = false;
  
  private epubBook: any = null;
  private epubRendition: any = null;

  constructor(
    private courseService: CourseService,
    private sanitizer: DomSanitizer,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnChanges(changes: SimpleChanges) {
    if (changes['selectedItem'] && this.selectedItem) {
      this.loadFile();
    }
  }

  ngAfterViewInit() {
    if (this.selectedItem?.extension === '.epub') {
      this.initEpub();
    }
  }

  ngOnDestroy() {
    this.cleanupEpub();
  }

  loadFile() {
    this.cleanupEpub();
    this.epubReady = false;
    this.sanitizedFileUrl = null;
    this.textContent = '';

    if (!this.selectedItem) return;

    const apiUrl = 'http://localhost:5000/api';
    // Use the path from the item to construct the file URL
    this.fileUrl = `${apiUrl}/files?path=${encodeURIComponent(this.selectedItem.path)}`;

    if (this.selectedItem.extension === '.pdf') {
      if (this.fileUrl && this.fileUrl.startsWith('http')) {
        this.sanitizedFileUrl = this.sanitizer.bypassSecurityTrustResourceUrl(this.fileUrl);
      } else {
        this.sanitizedFileUrl = null;
      }
      this.cdr.detectChanges();
    } else if (this.selectedItem.extension === '.txt') {
      fetch(this.fileUrl)
        .then(response => response.text())
        .then(text => {
          this.textContent = text;
          this.cdr.detectChanges();
        })
        .catch(error => console.error('Error loading text file:', error));
    } else if (this.selectedItem.extension === '.epub') {
      setTimeout(() => this.initEpub(), 100);
    }
  }

  initEpub() {
    if (!this.epubContainer || !this.selectedItem) return;

    this.cleanupEpub();

    this.epubBook = ePub(this.fileUrl);
    this.epubRendition = this.epubBook.renderTo(this.epubContainer.nativeElement, {
      width: '100%',
      height: '100%',
      spread: 'none'
    });

    this.epubRendition.display().then(() => {
      this.epubReady = true;
      this.cdr.detectChanges();
    });
  }

  epubNext() {
    if (this.epubRendition) {
      this.epubRendition.next();
    }
  }

  epubPrev() {
    if (this.epubRendition) {
      this.epubRendition.prev();
    }
  }

  cleanupEpub() {
    if (this.epubRendition) {
      this.epubRendition.destroy();
      this.epubRendition = null;
    }
    if (this.epubBook) {
      this.epubBook.destroy();
      this.epubBook = null;
    }
  }
}
