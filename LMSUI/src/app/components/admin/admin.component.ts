import { ChangeDetectorRef, Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatTabsModule } from '@angular/material/tabs';
import { HeaderComponent } from '../header/header.component';
import { CourseService } from '../../services/course.service';
import { BackupComponent } from './tabs/backup/backup.component';
import { UserManagementComponent } from './tabs/user-management/user-management.component';

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
    MatProgressBarModule,
    MatTabsModule,
    HeaderComponent,
    BackupComponent,
    UserManagementComponent
  ],
  template: `
    <div class="admin-container">
      <app-header></app-header>
      
      <div class="admin-content">
        <mat-tab-group class="admin-tabs">
          <!-- Scanner Tab -->
          <mat-tab>
            <ng-template mat-tab-label>
              <mat-icon class="tab-icon">search</mat-icon>
              Scanner
            </ng-template>
            <div class="tab-content">
              <mat-card class="admin-card">
                <mat-card-header>
                  <mat-card-title>
                    Course Scanner
                  </mat-card-title>
                </mat-card-header>
                <mat-card-content>
                  <p class="description">Scan a directory to import courses. Each root folder will become a category, and subfolders will become courses.</p>
                  
                  <mat-form-field appearance="outline" class="full-width">
                    <mat-label>Root Path</mat-label>
                    <input matInput [(ngModel)]="rootPath" placeholder="C:\\Courses" [disabled]="scanning">
                    <mat-icon matPrefix>folder</mat-icon>
                    <mat-hint>Enter the path containing your course folders</mat-hint>
                  </mat-form-field>
                  
                  @if (scanning) {
                    <mat-progress-bar mode="indeterminate" color="primary"></mat-progress-bar>
                    <p class="scanning-text">
                      <mat-icon>sync</mat-icon>
                      Scanning courses... Please wait
                    </p>
                  }
                  
                  <button mat-raised-button color="primary" (click)="scanCourses()" [disabled]="scanning" class="action-btn">
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
          </mat-tab>

          <!-- Backup Tab -->
          <mat-tab>
            <ng-template mat-tab-label>
              <mat-icon class="tab-icon">backup</mat-icon>
              Backup & Restore
            </ng-template>
            <div class="tab-content">
              <app-backup></app-backup>
            </div>
          </mat-tab>

          <!-- User Management Tab -->
          <mat-tab>
            <ng-template mat-tab-label>
              <mat-icon class="tab-icon">people</mat-icon>
              User Management
            </ng-template>
            <div class="tab-content">
              <app-user-management></app-user-management>
            </div>
          </mat-tab>
        </mat-tab-group>
      </div>
    </div>
  `,
  styles: [`
    .admin-container {
      display: flex;
      flex-direction: column;
      height: 100vh;
      overflow: hidden;
      background: #f5f7fa;
    }

    .admin-content {
      flex: 1;
      overflow-y: auto;
      padding: 24px;
    }

    .admin-tabs {
      background: white;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
      overflow: hidden;
    }

    .admin-tabs ::ng-deep .mat-mdc-tab-header {
      border-bottom: none;
      background: #f5f7fa;
    }

    .admin-tabs ::ng-deep .mat-mdc-tab {
      min-width: 160px;
    }

    .admin-tabs ::ng-deep .mat-mdc-tab .mdc-tab__text-label {
      color: #5f6368;
      font-weight: 500;
    }

    .admin-tabs ::ng-deep .mat-mdc-tab.mdc-tab--active .mdc-tab__text-label {
      color: #667eea;
    }

    .admin-tabs ::ng-deep .mdc-tab-indicator__content--underline {
      border-color: #667eea;
      border-width: 3px;
    }

    .tab-icon {
      margin-right: 8px;
      vertical-align: middle;
    }

    .tab-content {
      padding: 32px;
      min-height: 500px;
    }

    .admin-card {
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
    }

    .admin-card mat-card-header {
      padding: 20px 24px;
      border-bottom: 2px solid #e0e0e0;
    }

    .admin-card mat-card-title {
      font-size: 18px;
      font-weight: 600;
      margin: 0;
      color: #2c3e50;
    }

    .description {
      color: #5f6368;
      line-height: 1.6;
      margin-bottom: 24px;
    }

    .full-width {
      width: 100%;
      margin: 16px 0;
    }

    .action-btn {
      margin-top: 8px;
      padding: 0 32px;
      height: 44px;
      font-size: 15px;
      font-weight: 500;
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
      padding: 24px;
      border-radius: 12px;
      display: flex;
      gap: 16px;
      align-items: flex-start;
      animation: slideIn 0.3s ease;
    }

    @keyframes slideIn {
      from {
        opacity: 0;
        transform: translateY(-10px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    .result-summary.success {
      background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%);
      border: 2px solid #4caf50;
    }

    .result-summary.error {
      background: linear-gradient(135deg, #ffebee 0%, #ffcdd2 100%);
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
      color: #2c3e50;
      font-size: 18px;
      font-weight: 600;
    }

    .stats {
      display: flex;
      gap: 16px;
      margin: 16px 0;
      flex-wrap: wrap;
    }

    .stat-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 16px;
      background: white;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      transition: transform 0.2s;
    }

    .stat-item:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 8px rgba(0,0,0,0.15);
    }

    .stat-item mat-icon {
      color: #667eea;
    }

    .stat-item strong {
      color: #667eea;
      font-size: 20px;
      margin-right: 4px;
    }

    .message {
      color: #5f6368;
      margin: 12px 0;
      line-height: 1.6;
    }

    mat-progress-bar {
      margin: 16px 0;
      border-radius: 4px;
      overflow: hidden;
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
    private router: Router,
    private cdr: ChangeDetectorRef
  ) {}

  scanCourses() {
    this.scanning = true;
    this.scanResult = null;
    this.error = '';

    this.courseService.scanCourses(this.rootPath).subscribe({
      next: (response: ScanResult) => {
        this.scanning = false;
        this.scanResult = response;
        this.cdr.detectChanges();
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
