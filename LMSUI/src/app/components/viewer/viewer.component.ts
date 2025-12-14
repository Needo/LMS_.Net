import { ChangeDetectorRef, Component, Input, OnChanges } from '@angular/core';
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
          <h2>{{ selectedItem.name }}</h2>
          @if (selectedItem.type === 'video') {
            <video controls [src]="fileUrl" class="media"></video>
          }
          @if (selectedItem.type === 'audio') {
            <audio controls [src]="fileUrl" class="media"></audio>
          }
          @if (selectedItem.type === 'document' && selectedItem.extension === '.pdf') {
            <iframe [src]="sanitizeUrl(fileUrl)" class="document"></iframe>
          }
          @if (selectedItem.type === 'document' && selectedItem.extension === '.txt') {
          <pre class="document-text">{{ textContent }}</pre>
        }
          @if (selectedItem.type === 'document' && selectedItem.extension === '.html') {
          <iframe [src]="sanitizeUrl(fileUrl)" class="document"></iframe>
          }
         @if (
  selectedItem.type === 'document' &&
  selectedItem.extension !== '.pdf' &&
  selectedItem.extension !== '.txt' &&
  selectedItem.extension !== '.html'
  || selectedItem.type === 'file'
) {
            <div class="file-info">
              <mat-icon>description</mat-icon>
              <p>{{ selectedItem.name }}</p>
              <p>Size: {{ formatSize(selectedItem.size) }}</p>
              <a [href]="fileUrl" download mat-raised-button color="primary">
                <mat-icon>download</mat-icon> Download
              </a>
            </div>
          }
        </div>
      }
    </div>
  `,
  styles: [`
    .viewer { flex: 1; padding: 24px; overflow-y: auto; background: white; }
    .placeholder { display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%; color: #999; }
    .placeholder mat-icon { font-size: 64px; width: 64px; height: 64px; }
    .content h2 { margin-bottom: 24px; }
    .media { width: 100%; max-width: 800px; border-radius: 8px; }
    .document { width: 100%; height: 80vh; border: 1px solid #ddd; border-radius: 8px; }
    .file-info { padding: 24px; background: #f5f5f5; border-radius: 8px; text-align: center; }
    .file-info mat-icon { font-size: 64px; width: 64px; height: 64px; margin-bottom: 16px; }
  `]
})
export class ViewerComponent implements OnChanges {
  @Input() selectedItem: CourseItem | null = null;
  fileUrl: string = '';
  textContent: string = '';

  constructor(private courseService: CourseService, private sanitizer: DomSanitizer, private cdr: ChangeDetectorRef
) {}

  ngOnChanges() {
  if (this.selectedItem) {
    this.fileUrl = this.courseService.getFileUrl(this.selectedItem.path);
    this.textContent = '';

    if (this.selectedItem.extension === '.txt') {
      fetch(this.fileUrl)
        .then(res => res.text())
        .then(text => {
          this.textContent = text;
          this.cdr.detectChanges();   // 👈 forces UI update immediately
        })
        .catch(err => console.error('Failed to load text file', err));
    }
  } else {
    this.fileUrl = '';
    this.textContent = '';
  }
}



  sanitizeUrl(url: string): SafeResourceUrl {
    return this.sanitizer.bypassSecurityTrustResourceUrl(url);
  }

  formatSize(bytes: number): string {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1048576) return (bytes / 1024).toFixed(2) + ' KB';
    return (bytes / 1048576).toFixed(2) + ' MB';
  }
}
