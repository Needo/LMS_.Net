import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { CourseService } from '../../services/course.service';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [CommonModule, FormsModule, MatCardModule, MatFormFieldModule, MatInputModule, MatButtonModule, MatIconModule],
  template: `
    <div class="admin-panel">
      <button mat-icon-button (click)="goBack()">
        <mat-icon>arrow_back</mat-icon>
      </button>
      <h1>Admin Panel</h1>
      <mat-card>
        <mat-card-header><mat-card-title>Course Scanner</mat-card-title></mat-card-header>
        <mat-card-content>
          <p>Scan a directory to import courses.</p>
          <mat-form-field appearance="outline" class="full-width">
            <mat-label>Root Path</mat-label>
            <input matInput [(ngModel)]="rootPath" placeholder="C:\\Courses">
          </mat-form-field>
          <button mat-raised-button color="primary" (click)="scanCourses()" [disabled]="scanning">
            <mat-icon>search</mat-icon>
            {{ scanning ? 'Scanning...' : 'Scan Courses' }}
          </button>
          @if (message) {
            <div class="message" [class.error]="isError">
              <mat-icon>{{ isError ? 'error' : 'check_circle' }}</mat-icon>
              {{ message }}
            </div>
          }
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .admin-panel { padding: 24px; max-width: 800px; margin: 0 auto; }
    .full-width { width: 100%; margin: 16px 0; }
    .message { margin-top: 16px; padding: 12px; border-radius: 4px; background: #4caf50; color: white; display: flex; align-items: center; gap: 8px; }
    .message.error { background: #f44336; }
  `]
})
export class AdminComponent {
  rootPath = 'C:\\Courses';
  scanning = false;
  message = '';
  isError = false;

  constructor(private courseService: CourseService, private router: Router) {}

  scanCourses() {
    this.scanning = true;
    this.message = '';
    this.courseService.scanCourses(this.rootPath).subscribe({
      next: (response) => {
        this.scanning = false;
        this.message = response.message || 'Scan completed successfully!';
        this.isError = false;
      },
      error: (error) => {
        this.scanning = false;
        this.message = 'Error: ' + (error.error || error.message);
        this.isError = true;
      }
    });
  }

  goBack() { this.router.navigate(['/']); }
}
