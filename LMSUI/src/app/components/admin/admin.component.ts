import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { CourseService } from '../../services/course.service';

interface ScanResult {
  coursesAdded: number;
  foldersAdded: number;
  filesAdded: number;
  message: string;
}

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [
    CommonModule, 
    FormsModule, 
    MatCardModule, 
    MatFormFieldModule, 
    MatInputModule, 
    MatButtonModule, 
    MatIconModule,
    MatProgressBarModule
  ],
  template: `
    <div class="admin-panel">
      <button mat-icon-button (click)="goBack()">
        <mat-icon>arrow_back</mat-icon>
      </button>
      <h1>Admin Panel</h1>
      
      <mat-card>
        <mat-card-header>
          <mat-card-title>Course Scanner</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <p>Scan a directory to import courses. Each root folder will become a course.</p>
          
          <mat-form-field appearance="outline" class="full-width">
            <mat-label>Root Path</mat-label>
            <input matInput [(ngModel)]="rootPath" placeholder="C:\\Courses" [disabled]="scanning">
            <mat-hint>Enter the path containing your course folders</mat-hint>
          </mat-form-field>
          
          @if (scanning) {
            <mat-progress-bar mode="indeterminate" color="primary"></mat-progress-bar>
            <p class="scanning-text">
              <mat-icon>sync</mat-icon>
              Scanning courses... Please wait
            </p>
          }
          
          <button mat-raised-button color="primary" (click)="scanCourses()" [disabled]="scanning">
            <mat-icon>{{ scanning ? 'hourglass_empty' : 'search' }}</mat-icon>
            {{ scanning ? 'Scanning...' : 'Scan Courses' }}
          </button>
          
          @if (scanResult) {
            <div class="result-summary success">
              <mat-icon>check_circle</mat-icon>
              <div class="result-details">
                <h3>Scan Completed Successfully!</h3>
                <div class="stats">
                  <div class="stat-item">
                    <mat-icon>school</mat-icon>
                    <span><strong>{{ scanResult.coursesAdded }}</strong> Course(s)</span>
                  </div>
                  <div class="stat-item">
                    <mat-icon>folder</mat-icon>
                    <span><strong>{{ scanResult.foldersAdded }}</strong> Folder(s)</span>
                  </div>
                  <div class="stat-item">
                    <mat-icon>insert_drive_file</mat-icon>
                    <span><strong>{{ scanResult.filesAdded }}</strong> File(s)</span>
                  </div>
                </div>
                <p class="message">{{ scanResult.message }}</p>
                <button mat-button color="primary" (click)="goBack()">
                  <mat-icon>visibility</mat-icon>
                  View Courses
                </button>
              </div>
            </div>
          }
          
          @if (error) {
            <div class="result-summary error">
              <mat-icon>error</mat-icon>
              <div class="result-details">
                <h3>Scan Failed</h3>
                <p class="message">{{ error }}</p>
                <button mat-button color="warn" (click)="clearError()">
                  <mat-icon>close</mat-icon>
                  Dismiss
                </button>
              </div>
            </div>
          }
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .admin-panel {
      padding: 24px;
      max-width: 800px;
      margin: 0 auto;
    }
    .full-width {
      width: 100%;
      margin: 16px 0;
    }
    button[mat-raised-button] {
      margin-top: 8px;
    }
    .scanning-text {
      display: flex;
      align-items: center;
      gap: 8px;
      color: #666;
      margin: 16px 0;
      font-style: italic;
    }
    .scanning-text mat-icon {
      animation: spin 2s linear infinite;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    .result-summary {
      margin-top: 24px;
      padding: 20px;
      border-radius: 8px;
      display: flex;
      gap: 16px;
      align-items: flex-start;
    }
    .result-summary.success {
      background: #e8f5e9;
      border: 2px solid #4caf50;
    }
    .result-summary.error {
      background: #ffebee;
      border: 2px solid #f44336;
    }
    .result-summary > mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
    }
    .result-summary.success > mat-icon {
      color: #4caf50;
    }
    .result-summary.error > mat-icon {
      color: #f44336;
    }
    .result-details {
      flex: 1;
    }
    .result-details h3 {
      margin: 0 0 16px 0;
      color: #333;
    }
    .stats {
      display: flex;
      gap: 24px;
      margin: 16px 0;
      flex-wrap: wrap;
    }
    .stat-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 12px;
      background: white;
      border-radius: 4px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }
    .stat-item mat-icon {
      color: #1976d2;
    }
    .stat-item strong {
      color: #1976d2;
      font-size: 18px;
    }
    .message {
      color: #666;
      margin: 12px 0;
      line-height: 1.5;
    }
    mat-progress-bar {
      margin: 16px 0;
    }
  `]
})
export class AdminComponent {
  rootPath = 'C:\\Courses';
  scanning = false;
  scanResult: ScanResult | null = null;
  error = '';

  constructor(
    private courseService: CourseService,
    private router: Router
  ) {}

  scanCourses() {
    this.scanning = true;
    this.scanResult = null;
    this.error = '';
    
    this.courseService.scanCourses(this.rootPath).subscribe({
      next: (response: ScanResult) => {
        this.scanning = false;
        this.scanResult = response;
        console.log('Scan result:', response);
      },
      error: (err) => {
        this.scanning = false;
        this.error = err.message || 'Failed to scan courses. Please check the path and try again.';
        console.error('Scan error:', err);
      }
    });
  }

  clearError() {
    this.error = '';
  }

  goBack() {
    this.router.navigate(['/']);
  }
}
