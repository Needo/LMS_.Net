import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatTableModule } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { BackupService, BackupFile } from '../../../../services/backup.service';

@Component({
  selector: 'app-backup',
  standalone: true,
  imports: [
    CommonModule,
    MatTableModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatSnackBarModule
  ],
  template: `
    <div class="backup-container">
      <div class="header">
        <h2>Database Backup & Restore</h2>
        <button mat-raised-button color="primary" (click)="createBackup()" [disabled]="loading">
          <mat-icon>backup</mat-icon>
          Create Backup
        </button>
      </div>

      @if (loading) {
        <div class="loading">
          <mat-spinner diameter="50"></mat-spinner>
          <p>{{ loadingMessage }}</p>
        </div>
      }

      @if (!loading && backups.length === 0) {
        <div class="empty-state">
          <mat-icon>folder_open</mat-icon>
          <p>No backups found</p>
          <p class="hint">Create your first backup to get started</p>
        </div>
      }

      @if (!loading && backups.length > 0) {
        <table mat-table [dataSource]="backups" class="backup-table">
          <ng-container matColumnDef="fileName">
            <th mat-header-cell *matHeaderCellDef>File Name</th>
            <td mat-cell *matCellDef="let backup">{{ backup.fileName }}</td>
          </ng-container>

          <ng-container matColumnDef="size">
            <th mat-header-cell *matHeaderCellDef>Size</th>
            <td mat-cell *matCellDef="let backup">{{ backup.formattedSize }}</td>
          </ng-container>

          <ng-container matColumnDef="date">
            <th mat-header-cell *matHeaderCellDef>Created Date</th>
            <td mat-cell *matCellDef="let backup">{{ backup.createdDate | date:'medium' }}</td>
          </ng-container>

          <ng-container matColumnDef="actions">
            <th mat-header-cell *matHeaderCellDef>Actions</th>
            <td mat-cell *matCellDef="let backup">
              <button mat-icon-button color="primary" 
                      (click)="restoreBackup(backup)">
                <mat-icon>restore</mat-icon>
              </button>
              <button mat-icon-button color="warn" 
                      (click)="deleteBackup(backup)">
                <mat-icon>delete</mat-icon>
              </button>
            </td>
          </ng-container>

          <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
          <tr mat-row *matRowDef="let row; columns: displayedColumns;"></tr>
        </table>
      }
    </div>
  `,
  styles: [`
    .backup-container {
      padding: 24px;
    }

    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }

    .header h2 {
      margin: 0;
      font-size: 24px;
      font-weight: 500;
    }

    .header button mat-icon {
      margin-right: 8px;
    }

    .loading {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 48px;
      gap: 16px;
    }

    .empty-state {
      text-align: center;
      padding: 48px;
      color: #666;
    }

    .empty-state mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      color: #ccc;
      margin-bottom: 16px;
    }

    .empty-state .hint {
      font-size: 12px;
      color: #999;
    }

    .backup-table {
      width: 100%;
      background: white;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .mat-column-actions {
      width: 120px;
      text-align: center;
    }
  `]
})
export class BackupComponent implements OnInit {
  backups: BackupFile[] = [];
  loading = false;
  loadingMessage = '';
  displayedColumns = ['fileName', 'size', 'date', 'actions'];

  constructor(
    private backupService: BackupService,
    private snackBar: MatSnackBar,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit() {
    // Delay to avoid ExpressionChangedAfterItHasBeenChecked error
    setTimeout(() => {
      this.loadBackups();
    });
  }

  loadBackups() {
    this.loading = true;
    this.loadingMessage = 'Loading backups...';
    this.cdr.detectChanges();
    
    this.backupService.listBackups().subscribe({
      next: (backups) => {
        this.backups = backups;
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (error) => {
        console.error('Error loading backups:', error);
        this.snackBar.open('Error loading backups', 'Close', { duration: 3000 });
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  createBackup() {
    this.loading = true;
    this.loadingMessage = 'Creating backup...';
    this.cdr.detectChanges();

    this.backupService.createBackup().subscribe({
      next: (response) => {
        this.snackBar.open(response.message, 'Close', { duration: 3000 });
        this.loadBackups();
      },
      error: (error) => {
        console.error('Error creating backup:', error);
        this.snackBar.open('Error creating backup', 'Close', { duration: 3000 });
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  restoreBackup(backup: BackupFile) {
    if (!confirm(`Are you sure you want to restore backup "${backup.fileName}"? This will overwrite the current database.`)) {
      return;
    }

    this.loading = true;
    this.loadingMessage = 'Restoring backup...';
    this.cdr.detectChanges();

    this.backupService.restoreBackup(backup.fileName).subscribe({
      next: (response) => {
        this.snackBar.open(response.message, 'Close', { duration: 3000 });
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (error) => {
        console.error('Error restoring backup:', error);
        this.snackBar.open('Error restoring backup', 'Close', { duration: 3000 });
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  deleteBackup(backup: BackupFile) {
    if (!confirm(`Are you sure you want to delete backup "${backup.fileName}"?`)) {
      return;
    }

    this.backupService.deleteBackup(backup.fileName).subscribe({
      next: (response) => {
        this.snackBar.open(response.message, 'Close', { duration: 3000 });
        this.loadBackups();
      },
      error: (error) => {
        console.error('Error deleting backup:', error);
        this.snackBar.open('Error deleting backup', 'Close', { duration: 3000 });
      }
    });
  }
}
