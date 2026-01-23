import { Component, EventEmitter, Output, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { RouterModule, Router } from '@angular/router';
import { AuthService, CurrentUser } from '../../services/auth.service';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatInputModule,
    MatFormFieldModule,
    MatProgressSpinnerModule,
    RouterModule
  ],
  template: `
    <mat-toolbar class="modern-header">
      <div class="header-content">
        <div class="brand-section">
          <mat-icon class="brand-icon">school</mat-icon>
          <span class="app-title">Learning Management System</span>
          <span class="version-badge">v2.0</span>
        </div>
        
        @if (!isAdminRoute) {
          <div class="search-container">
            <mat-form-field appearance="outline" class="search-field">
              <mat-icon matPrefix class="search-icon">search</mat-icon>
              <input 
                matInput 
                placeholder="Search files and courses..." 
                [(ngModel)]="searchQuery"
                (keyup.enter)="onSearch()"
                [disabled]="searching">
              @if (searching) {
                <mat-spinner matSuffix diameter="20"></mat-spinner>
              } @else if (searchQuery) {
                <button mat-icon-button matSuffix (click)="clearSearch()" class="clear-btn">
                  <mat-icon>close</mat-icon>
                </button>
              }
            </mat-form-field>
          </div>
        } @else {
          <div class="admin-title">
            <mat-icon>admin_panel_settings</mat-icon>
            <span>Admin Panel</span>
          </div>
        }

        @if (currentUser) {
          <div class="user-section">
            <div class="user-info">
              <div class="user-avatar">
                {{ getInitials(currentUser.firstName, currentUser.lastName) }}
              </div>
              <span class="user-name">{{ currentUser.firstName }} {{ currentUser.lastName }}</span>
            </div>
            
            <div class="nav-buttons">
              @if (!isAdminRoute) {
                <button mat-stroked-button routerLink="/" class="nav-btn">
                  <mat-icon>home</mat-icon>
                  <span>Home</span>
                </button>
                
                @if (isAdmin) {
                  <button mat-stroked-button routerLink="/admin" class="nav-btn admin-btn">
                    <mat-icon>admin_panel_settings</mat-icon>
                    <span>Admin</span>
                  </button>
                }
              } @else {
                @if (isAdmin) {
                  <button mat-stroked-button routerLink="/" class="nav-btn">
                    <mat-icon>arrow_back</mat-icon>
                    <span>Back to Client</span>
                  </button>
                }
              }
              
              <button mat-stroked-button (click)="logout()" class="nav-btn logout-btn">
                <mat-icon>logout</mat-icon>
                <span>Logout</span>
              </button>
            </div>
          </div>
        } @else {
          <div class="user-section">
            <button mat-raised-button color="accent" routerLink="/login" class="login-btn">
              <mat-icon>login</mat-icon>
              Login
            </button>
          </div>
        }
      </div>
    </mat-toolbar>
  `,
  styles: [`
    .modern-header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
      padding: 0;
      height: 70px;
      position: sticky;
      top: 0;
      z-index: 1000;
    }

    .header-content {
      display: grid;
      grid-template-columns: auto 1fr auto;
      align-items: center;
      gap: 32px;
      width: 100%;
      padding: 0 24px;
      height: 100%;
    }

    /* Brand Section */
    .brand-section {
      display: flex;
      align-items: center;
      gap: 12px;
      min-width: 280px;
    }

    .brand-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
      color: white;
    }

    .app-title {
      font-size: 18px;
      font-weight: 600;
      color: white;
      letter-spacing: 0.5px;
      white-space: nowrap;
    }

    .version-badge {
      background: rgba(255, 255, 255, 0.2);
      color: white;
      padding: 2px 8px;
      border-radius: 12px;
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.5px;
    }

    /* Admin Title */
    .admin-title {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 12px;
      color: white;
      font-size: 20px;
      font-weight: 600;
    }

    .admin-title mat-icon {
      font-size: 28px;
      width: 28px;
      height: 28px;
    }

    /* Search Section */
    .search-container {
      justify-self: center;
      width: 100%;
      max-width: 600px;
    }

    .search-field {
      width: 100%;
      margin: 0;
    }

    .search-field ::ng-deep .mat-mdc-text-field-wrapper {
      background: rgba(255, 255, 255, 0.95);
      border-radius: 24px;
      padding: 0 4px;
    }

    .search-field ::ng-deep .mdc-notched-outline {
      display: none;
    }

    .search-field ::ng-deep .mat-mdc-form-field-subscript-wrapper {
      display: none;
    }

    .search-field ::ng-deep input {
      color: #2c3e50;
      font-size: 14px;
    }

    .search-field ::ng-deep input::placeholder {
      color: #7f8c8d;
    }

    .search-icon {
      color: #667eea !important;
      margin-left: 8px;
    }

    .clear-btn {
      color: #95a5a6;
    }

    .search-field ::ng-deep mat-spinner circle {
      stroke: #667eea;
    }

    /* User Section */
    .user-section {
      display: flex;
      align-items: center;
      gap: 20px;
      justify-self: end;
    }

    .user-info {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .user-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: rgba(255, 255, 255, 0.2);
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
      font-size: 14px;
      color: white;
      border: 2px solid rgba(255, 255, 255, 0.3);
    }

    .user-name {
      font-size: 14px;
      color: white;
      font-weight: 500;
    }

    .nav-buttons {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .nav-btn {
      color: white;
      border-color: rgba(255, 255, 255, 0.3);
      font-size: 13px;
      font-weight: 500;
      transition: all 0.3s ease;
    }

    .nav-btn:hover {
      background: rgba(255, 255, 255, 0.15);
      border-color: rgba(255, 255, 255, 0.5);
    }

    .nav-btn mat-icon {
      font-size: 18px;
      width: 18px;
      height: 18px;
      margin-right: 6px;
    }

    .admin-btn:hover {
      background: rgba(255, 193, 7, 0.2);
      border-color: #ffc107;
    }

    .logout-btn:hover {
      background: rgba(244, 67, 54, 0.2);
      border-color: #f44336;
    }

    .login-btn {
      background: white;
      color: #667eea;
      font-weight: 600;
      padding: 0 24px;
    }

    .login-btn mat-icon {
      margin-right: 8px;
    }

    .login-btn:hover {
      background: #f8f9fa;
    }

    /* Responsive */
    @media (max-width: 1200px) {
      .header-content {
        gap: 16px;
      }

      .brand-section {
        min-width: auto;
      }

      .app-title {
        display: none;
      }

      .search-container {
        max-width: 400px;
      }
    }

    @media (max-width: 768px) {
      .user-name {
        display: none;
      }

      .nav-btn span {
        display: none;
      }

      .nav-btn mat-icon {
        margin-right: 0;
      }
    }
  `]
})
export class HeaderComponent implements OnInit {
  @Output() search = new EventEmitter<string>();
  @Output() searchingChange = new EventEmitter<boolean>();
  
  currentUser: CurrentUser | null = null;
  searchQuery = '';
  isAdmin = false;
  searching = false;
  isAdminRoute = false;

  constructor(
    private authService: AuthService,
    private router: Router
  ) {
    // Watch for route changes
    this.router.events.subscribe(() => {
      this.isAdminRoute = this.router.url.startsWith('/admin');
    });
  }

  ngOnInit() {
    this.authService.currentUser$.subscribe(user => {
      this.currentUser = user;
      this.isAdmin = this.authService.isAdmin;
    });
    
    // Set initial route state
    this.isAdminRoute = this.router.url.startsWith('/admin');
  }

  getInitials(firstName: string, lastName: string): string {
    return `${firstName?.charAt(0) || ''}${lastName?.charAt(0) || ''}`.toUpperCase();
  }

  onSearch() {
    if (this.searchQuery.trim()) {
      this.searching = true;
      this.searchingChange.emit(true);
      this.search.emit(this.searchQuery.trim());
    }
  }

  stopSearching() {
    this.searching = false;
    this.searchingChange.emit(false);
  }

  clearSearch() {
    this.searchQuery = '';
    this.searching = false;
    this.searchingChange.emit(false);
    this.search.emit('');
  }

  logout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
