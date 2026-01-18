import { Component, EventEmitter, Output, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatMenuModule } from '@angular/material/menu';
import { MatDividerModule } from '@angular/material/divider';
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
    MatMenuModule,
    MatDividerModule,
    RouterModule
  ],
  template: `
    <mat-toolbar color="primary" class="header-toolbar">
      <span class="app-title">LMS v2</span>
      
      <!-- Search Box (Center) -->
      <div class="search-container">
        <mat-form-field appearance="outline" class="search-field">
          <mat-icon matPrefix>search</mat-icon>
          <input 
            matInput 
            placeholder="Search files and courses..." 
            [(ngModel)]="searchQuery"
            (keyup.enter)="onSearch()"
            (input)="onSearchInput()">
          @if (searchQuery) {
            <button mat-icon-button matSuffix (click)="clearSearch()">
              <mat-icon>close</mat-icon>
            </button>
          }
        </mat-form-field>
      </div>

      <span class="spacer"></span>

      <!-- User Info & Menu (Right) -->
      @if (currentUser) {
        <div class="user-section">
          <span class="user-name">{{ currentUser.firstName }} {{ currentUser.lastName }}</span>
          
          <button mat-icon-button [matMenuTriggerFor]="userMenu">
            <mat-icon>account_circle</mat-icon>
          </button>
          
          <mat-menu #userMenu="matMenu">
            <div class="user-menu-header">
              <div class="user-info">
                <strong>{{ currentUser.firstName }} {{ currentUser.lastName }}</strong>
                <span>{{ currentUser.email }}</span>
                <span class="user-role">{{ currentUser.role }}</span>
              </div>
            </div>
            <mat-divider></mat-divider>
            
            @if (isAdmin) {
              <button mat-menu-item routerLink="/admin">
                <mat-icon>settings</mat-icon>
                <span>Admin Panel</span>
              </button>
            }
            
            <button mat-menu-item (click)="logout()">
              <mat-icon>exit_to_app</mat-icon>
              <span>Logout</span>
            </button>
          </mat-menu>
        </div>
      } @else {
        <button mat-raised-button color="accent" routerLink="/login">
          <mat-icon>login</mat-icon>
          Login
        </button>
      }
    </mat-toolbar>
  `,
  styles: [`
    .header-toolbar {
      display: flex;
      align-items: center;
      padding: 0 24px;
      gap: 16px;
      height: 64px;
    }

    .app-title {
      font-size: 20px;
      font-weight: 500;
      white-space: nowrap;
    }

    .search-container {
      flex: 0 1 600px;
      max-width: 600px;
      margin: 0 auto;
    }

    .search-field {
      width: 100%;
      margin: 0;
    }

    .search-field ::ng-deep .mat-mdc-form-field-subscript-wrapper {
      display: none;
    }

    .search-field ::ng-deep .mat-mdc-text-field-wrapper {
      background: rgba(255, 255, 255, 0.15);
      border-radius: 4px;
    }

    .search-field ::ng-deep .mat-mdc-form-field-focus-overlay {
      background: rgba(255, 255, 255, 0.1);
    }

    .search-field ::ng-deep input {
      color: white;
      caret-color: white;
    }

    .search-field ::ng-deep input::placeholder {
      color: rgba(255, 255, 255, 0.7);
    }

    .search-field ::ng-deep .mat-icon {
      color: rgba(255, 255, 255, 0.9);
    }

    .spacer {
      flex: 1 1 auto;
    }

    .user-section {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .user-name {
      font-size: 14px;
      color: rgba(255, 255, 255, 0.9);
    }

    .user-menu-header {
      padding: 16px;
      background: #f5f5f5;
    }

    .user-info {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .user-info strong {
      font-size: 16px;
      color: #333;
    }

    .user-info span {
      font-size: 13px;
      color: #666;
    }

    .user-role {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 12px;
      font-size: 11px;
      font-weight: 500;
      background: #e3f2fd;
      color: #1976d2;
      margin-top: 4px;
      width: fit-content;
    }
  `]
})
export class HeaderComponent implements OnInit {
  @Output() search = new EventEmitter<string>();
  
  currentUser: CurrentUser | null = null;
  searchQuery = '';
  isAdmin = false;

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit() {
    this.authService.currentUser$.subscribe(user => {
      this.currentUser = user;
      this.isAdmin = this.authService.isAdmin;
    });
  }

  onSearch() {
    if (this.searchQuery.trim()) {
      this.search.emit(this.searchQuery.trim());
    }
  }

  onSearchInput() {
    // Optional: implement real-time search with debounce
    if (this.searchQuery.length > 2) {
      // this.search.emit(this.searchQuery.trim());
    }
  }

  clearSearch() {
    this.searchQuery = '';
    this.search.emit(''); // Clear search results
  }

  logout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
