import { Component, OnInit, Inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { MatTableModule } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatDialog, MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatListModule } from '@angular/material/list';
import { UserService, User, CreateUserRequest, UpdateUserRequest } from '../../../../services/user.service';
import { CourseService } from '../../../../services/course.service';
import { Course } from '../../../../models/course.model';

@Component({
  selector: 'app-user-management',
  standalone: true,
  imports: [
    CommonModule,
    MatTableModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
    MatDialogModule
  ],
  template: `
    <div class="user-management-container">
      <div class="header">
        <h2>User Management</h2>
        <button mat-raised-button color="primary" (click)="openAddUserDialog()">
          <mat-icon>person_add</mat-icon>
          Add User
        </button>
      </div>

      @if (loading) {
        <div class="loading">
          <mat-spinner diameter="50"></mat-spinner>
          <p>Loading users...</p>
        </div>
      }

      @if (!loading && users.length === 0) {
        <div class="empty-state">
          <mat-icon>people</mat-icon>
          <p>No users found</p>
        </div>
      }

      @if (!loading && users.length > 0) {
        <table mat-table [dataSource]="users" class="users-table">
          <ng-container matColumnDef="email">
            <th mat-header-cell *matHeaderCellDef>Email</th>
            <td mat-cell *matCellDef="let user">{{ user.email }}</td>
          </ng-container>

          <ng-container matColumnDef="name">
            <th mat-header-cell *matHeaderCellDef>Name</th>
            <td mat-cell *matCellDef="let user">{{ user.firstName }} {{ user.lastName }}</td>
          </ng-container>

          <ng-container matColumnDef="sex">
            <th mat-header-cell *matHeaderCellDef>Gender</th>
            <td mat-cell *matCellDef="let user">{{ user.sex }}</td>
          </ng-container>

          <ng-container matColumnDef="role">
            <th mat-header-cell *matHeaderCellDef>Role</th>
            <td mat-cell *matCellDef="let user">
              <span class="role-badge" [class.admin]="user.role === 'Admin'">
                {{ user.role }}
              </span>
            </td>
          </ng-container>

          <ng-container matColumnDef="createdDate">
            <th mat-header-cell *matHeaderCellDef>Created</th>
            <td mat-cell *matCellDef="let user">{{ user.createdDate | date:'short' }}</td>
          </ng-container>

          <ng-container matColumnDef="actions">
            <th mat-header-cell *matHeaderCellDef>Actions</th>
            <td mat-cell *matCellDef="let user">
              <button mat-icon-button (click)="openEditUserDialog(user)">
                <mat-icon>edit</mat-icon>
              </button>
              <button mat-icon-button (click)="openSubscriptionsDialog(user)">
                <mat-icon>school</mat-icon>
              </button>
              <button mat-icon-button color="warn" (click)="deleteUser(user)">
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
    .user-management-container {
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

    .users-table {
      width: 100%;
      background: white;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }

    .role-badge {
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 500;
      background: #e3f2fd;
      color: #1976d2;
    }

    .role-badge.admin {
      background: #fff3e0;
      color: #f57c00;
    }

    .mat-column-actions {
      width: 160px;
    }
  `]
})
export class UserManagementComponent implements OnInit {
  users: User[] = [];
  loading = false;
  displayedColumns = ['email', 'name', 'sex', 'role', 'createdDate', 'actions'];

  constructor(
    private userService: UserService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit() {
    setTimeout(() => {
      this.loadUsers();
    });
  }

  loadUsers() {
    this.loading = true;
    this.cdr.detectChanges();
    
    this.userService.getAllUsers().subscribe({
      next: (users) => {
        this.users = users;
        this.loading = false;
        this.cdr.detectChanges();
      },
      error: (error) => {
        console.error('Error loading users:', error);
        this.snackBar.open('Error loading users', 'Close', { duration: 3000 });
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  openAddUserDialog() {
    const dialogRef = this.dialog.open(AddEditUserDialog, {
      width: '500px',
      data: { mode: 'add' }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.loadUsers();
      }
    });
  }

  openEditUserDialog(user: User) {
    const dialogRef = this.dialog.open(AddEditUserDialog, {
      width: '500px',
      data: { mode: 'edit', user }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.loadUsers();
      }
    });
  }

  openSubscriptionsDialog(user: User) {
    this.dialog.open(SubscriptionsDialog, {
      width: '600px',
      maxHeight: '80vh',
      data: { user }
    });
  }

  deleteUser(user: User) {
    if (!confirm(`Are you sure you want to delete user "${user.email}"?`)) {
      return;
    }

    this.userService.deleteUser(user.id).subscribe({
      next: () => {
        this.snackBar.open('User deleted successfully', 'Close', { duration: 3000 });
        this.loadUsers();
      },
      error: (error) => {
        console.error('Error deleting user:', error);
        this.snackBar.open('Error deleting user', 'Close', { duration: 3000 });
      }
    });
  }
}

// Add/Edit User Dialog
@Component({
  selector: 'add-edit-user-dialog',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule
  ],
  template: `
    <h2 mat-dialog-title>{{ data.mode === 'add' ? 'Add User' : 'Edit User' }}</h2>
    <mat-dialog-content>
      <form [formGroup]="userForm">
        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Email</mat-label>
          <input matInput formControlName="email" [readonly]="data.mode === 'edit'">
          <mat-error *ngIf="userForm.get('email')?.hasError('required')">Email is required</mat-error>
          <mat-error *ngIf="userForm.get('email')?.hasError('email')">Invalid email</mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>First Name</mat-label>
          <input matInput formControlName="firstName">
          <mat-error>First name is required</mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Last Name</mat-label>
          <input matInput formControlName="lastName">
          <mat-error>Last name is required</mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Gender</mat-label>
          <mat-select formControlName="sex">
            <mat-option value="Male">Male</mat-option>
            <mat-option value="Female">Female</mat-option>
          </mat-select>
          <mat-error>Gender is required</mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>Role</mat-label>
          <mat-select formControlName="role">
            <mat-option value="Student">Student</mat-option>
            <mat-option value="Admin">Admin</mat-option>
          </mat-select>
          <mat-error>Role is required</mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="full-width">
          <mat-label>{{ data.mode === 'add' ? 'Password' : 'New Password (leave blank to keep current)' }}</mat-label>
          <input matInput type="password" formControlName="password">
          <mat-error *ngIf="data.mode === 'add'">Password is required</mat-error>
        </mat-form-field>
      </form>
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button (click)="cancel()">Cancel</button>
      <button mat-raised-button color="primary" (click)="save()" [disabled]="!userForm.valid || saving">
        {{ saving ? 'Saving...' : 'Save' }}
      </button>
    </mat-dialog-actions>
  `,
  styles: [`
    .full-width {
      width: 100%;
      margin-bottom: 16px;
    }
  `]
})
export class AddEditUserDialog {
  userForm: FormGroup;
  saving = false;

  constructor(
    private fb: FormBuilder,
    private userService: UserService,
    private snackBar: MatSnackBar,
    public dialogRef: MatDialogRef<AddEditUserDialog>,
    @Inject(MAT_DIALOG_DATA) public data: { mode: 'add' | 'edit', user?: User }
  ) {
    const passwordValidators = data.mode === 'add' ? [Validators.required, Validators.minLength(6)] : [];
    
    this.userForm = this.fb.group({
      email: [data.user?.email || '', [Validators.required, Validators.email]],
      firstName: [data.user?.firstName || '', Validators.required],
      lastName: [data.user?.lastName || '', Validators.required],
      sex: [data.user?.sex || '', Validators.required],
      role: [data.user?.role || 'Student', Validators.required],
      password: ['', passwordValidators]
    });
  }

  cancel() {
    this.dialogRef.close();
  }

  save() {
    if (!this.userForm.valid) return;

    this.saving = true;
    const formValue = this.userForm.value;

    if (this.data.mode === 'add') {
      const request: CreateUserRequest = {
        email: formValue.email,
        password: formValue.password,
        firstName: formValue.firstName,
        lastName: formValue.lastName,
        sex: formValue.sex,
        role: formValue.role
      };

      this.userService.createUser(request).subscribe({
        next: () => {
          this.snackBar.open('User created successfully', 'Close', { duration: 3000 });
          this.dialogRef.close(true);
        },
        error: (error) => {
          console.error('Error creating user:', error);
          this.snackBar.open(error.error?.message || 'Error creating user', 'Close', { duration: 3000 });
          this.saving = false;
        }
      });
    } else {
      const request: UpdateUserRequest = {
        firstName: formValue.firstName,
        lastName: formValue.lastName,
        sex: formValue.sex,
        role: formValue.role,
        newPassword: formValue.password || undefined
      };

      this.userService.updateUser(this.data.user!.id, request).subscribe({
        next: () => {
          this.snackBar.open('User updated successfully', 'Close', { duration: 3000 });
          this.dialogRef.close(true);
        },
        error: (error) => {
          console.error('Error updating user:', error);
          this.snackBar.open('Error updating user', 'Close', { duration: 3000 });
          this.saving = false;
        }
      });
    }
  }
}

// Subscriptions Dialog
@Component({
  selector: 'subscriptions-dialog',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    MatCheckboxModule,
    MatButtonModule,
    MatProgressSpinnerModule,
    MatListModule,
    MatIconModule,
    FormsModule
  ],
  template: `
    <h2 mat-dialog-title>Manage Course Subscriptions</h2>
    <div class="user-info">
      <mat-icon>person</mat-icon>
      {{ data.user.firstName }} {{ data.user.lastName }} ({{ data.user.email }})
    </div>
    
    <mat-dialog-content>
      @if (loading) {
        <div class="loading">
          <mat-spinner diameter="40"></mat-spinner>
          <p>Loading courses...</p>
        </div>
      }

      @if (!loading && allCourses.length === 0) {
        <div class="empty-state">
          <mat-icon>school</mat-icon>
          <p>No courses available</p>
        </div>
      }

      @if (!loading && allCourses.length > 0) {
        <div class="courses-list">
          @for (course of allCourses; track course.id) {
            <div class="course-item">
              <mat-checkbox 
                [checked]="isSubscribed(course.id)"
                (change)="toggleSubscription(course.id, $event.checked)">
                {{ course.name }}
              </mat-checkbox>
            </div>
          }
        </div>
      }
    </mat-dialog-content>
    
    <mat-dialog-actions align="end">
      <button mat-raised-button color="primary" (click)="close()">Close</button>
    </mat-dialog-actions>
  `,
  styles: [`
    .user-info {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 24px;
      background: #f5f5f5;
      border-radius: 4px;
      margin-bottom: 16px;
      font-size: 14px;
      color: #666;
    }

    .user-info mat-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
    }

    .loading {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 48px;
      gap: 16px;
    }

    .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 48px;
      color: #999;
    }

    .empty-state mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 16px;
    }

    .courses-list {
      max-height: 400px;
      overflow-y: auto;
      padding: 8px 0;
    }

    .course-item {
      padding: 12px 16px;
      border-bottom: 1px solid #f0f0f0;
    }

    .course-item:hover {
      background: #fafafa;
    }

    .course-item:last-child {
      border-bottom: none;
    }
  `]
})
export class SubscriptionsDialog implements OnInit {
  loading = false; // Start with false to avoid change detection error
  allCourses: Course[] = [];
  subscribedCourseIds: number[] = [];

  constructor(
    private userService: UserService,
    private courseService: CourseService,
    private snackBar: MatSnackBar,
    private cdr: ChangeDetectorRef,
    public dialogRef: MatDialogRef<SubscriptionsDialog>,
    @Inject(MAT_DIALOG_DATA) public data: { user: User }
  ) {}

  ngOnInit() {
    // Delay to avoid ExpressionChangedAfterItHasBeenChecked error
    setTimeout(() => {
      this.loadData();
    });
  }

  loadData() {
    this.loading = true;
    this.cdr.detectChanges();
    console.log('=== Loading subscriptions for user:', this.data.user.id);

    // Load subscribed course IDs first (faster query)
    this.userService.getSubscribedCourseIds(this.data.user.id).subscribe({
      next: (courseIds) => {
        this.subscribedCourseIds = courseIds;
        console.log('✓ Subscribed IDs:', courseIds);

        // Then load all courses
        this.courseService.getCourses().subscribe({
          next: (courses) => {
            this.allCourses = courses;
            this.loading = false;
            this.cdr.detectChanges();
            console.log('✓ Loaded courses:', courses.length);
          },
          error: (error) => {
            console.error('✗ Error loading courses:', error);
            this.snackBar.open('Error loading courses', 'Close', { duration: 3000 });
            this.loading = false;
            this.cdr.detectChanges();
          }
        });
      },
      error: (error) => {
        console.error('✗ Error loading subscriptions:', error);
        this.snackBar.open('Error loading subscriptions', 'Close', { duration: 3000 });
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  isSubscribed(courseId: number): boolean {
    return this.subscribedCourseIds.includes(courseId);
  }

  toggleSubscription(courseId: number, isChecked: boolean) {
    console.log('Toggle subscription:', courseId, isChecked);
    
    if (isChecked) {
      this.userService.subscribe(this.data.user.id, courseId).subscribe({
        next: () => {
          this.subscribedCourseIds.push(courseId);
          this.snackBar.open('Subscribed', 'Close', { duration: 2000 });
        },
        error: (error) => {
          console.error('Error subscribing:', error);
          this.snackBar.open('Error subscribing', 'Close', { duration: 3000 });
        }
      });
    } else {
      this.userService.unsubscribe(this.data.user.id, courseId).subscribe({
        next: () => {
          this.subscribedCourseIds = this.subscribedCourseIds.filter(id => id !== courseId);
          this.snackBar.open('Unsubscribed', 'Close', { duration: 2000 });
        },
        error: (error) => {
          console.error('Error unsubscribing:', error);
          this.snackBar.open('Error unsubscribing', 'Close', { duration: 3000 });
        }
      });
    }
  }

  close() {
    this.dialogRef.close();
  }
}
