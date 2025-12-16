import { ChangeDetectorRef, Component, Input, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { MatIconModule } from '@angular/material/icon';
import { MatButtonModule } from '@angular/material/button';
import { CourseItem } from '../../models/course.model';
import { CourseService } from '../../services/course.service';

@Component({
  selector: 'app-viewer',
  standalone: true,
  imports: [CommonModule, MatIconModule, MatButtonModule],
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
            <iframe [src]="sanitizeUrl(fileUrl)" class="document-viewer"></iframe>
          }
          
          @if (selectedItem.type === 'document' && selectedItem.extension === '.txt') {
            <div class="text-viewer">
              <pre class="text-content">{{ textContent }}</pre>
            </div>
          }
          
          @if (selectedItem.type === 'document' && selectedItem.extension === '.html') {
            <iframe [src]="sanitizeUrl(fileUrl)" class="document-viewer"></iframe>
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

    .file-header {
      padding: 16px 24px;
      border-bottom: 1px solid #e0e0e0;
      flex-shrink: 0;
    }

    .file-header h2 {
      margin: 0;
      font-size: 18px;
      font-weight: 500;
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
export class ViewerComponent implements OnChanges {
  @Input() selectedItem: CourseItem | null = null;
  fileUrl: string = '';
  textContent: string = '';
  private previousItemId: number | null = null;

  constructor(
    private courseService: CourseService,
    private sanitizer: DomSanitizer,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnChanges(changes: SimpleChanges) {
    if (changes['selectedItem'] && this.selectedItem) {
      if (this.previousItemId !== this.selectedItem.id) {
        this.previousItemId = this.selectedItem.id;
        this.textContent = '';
        this.fileUrl = '';
        this.cdr.detectChanges();
        this.loadContent();
      }
    } else if (!this.selectedItem) {
      this.fileUrl = '';
      this.textContent = '';
      this.previousItemId = null;
    }
  }

  private loadContent() {
    if (!this.selectedItem) return;

    this.fileUrl = this.courseService.getFileUrl(this.selectedItem.path);

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
    }
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
}