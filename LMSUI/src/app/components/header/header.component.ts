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
    <mat-toolbar color="primary" class="header-toolbar">
      <span class="app-title">Learning Management System V2.0</span>
      
      <div class="search-container">
        <mat-form-field appearance="outline" class="search-field">
          <mat-icon matPrefix>search</mat-icon>
          <input 
            matInput 
            placeholder="Search files and courses..." 
            [(ngModel)]="searchQuery"
            (keyup.enter)="onSearch()"
            [disabled]="searching">
          @if (searching) {
            <mat-spinner matSuffix diameter="20"></mat-spinner>
          } @else if (searchQuery) {
            <button mat-icon-button matSuffix (click)="clearSearch()">
              <mat-icon>close</mat-icon>
            </button>
          }
        </mat-form-field>
      </div>

      @if (currentUser) {
        <div class="nav-buttons">
          <span class="user-name">{{ currentUser.firstName }} {{ currentUser.lastName }}</span>
          
          <button mat-button routerLink="/">
            <mat-icon>home</mat-icon>
            Home
          </button>
          
          @if (isAdmin) {
            <button mat-button routerLink="/admin">
              <mat-icon>settings</mat-icon>
              Admin
            </button>
          }
          
          <button mat-button (click)="logout()">
            <mat-icon>exit_to_app</mat-icon>
            Logout
          </button>
        </div>
      } @else {
        <div class="nav-buttons">
          <button mat-raised-button color="accent" routerLink="/login">
            <mat-icon>login</mat-icon>
            Login
          </button>
        </div>
      }
    </mat-toolbar>
  `,
  styles: [`
    .header-toolbar {
      display: grid;
      grid-template-columns: 300px 1fr auto;
      align-items: center;
      padding: 0 24px;
      height: 64px;
      gap: 24px;
    }

    .app-title {
      font-size: 18px;
      font-weight: 500;
      white-space: nowrap;
    }

    .search-container {
      justify-self: center;
      width: 100%;
      max-width: 700px;
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

    .search-field ::ng-deep mat-spinner {
      margin-right: 8px;
    }

    .search-field ::ng-deep mat-spinner circle {
      stroke: white;
    }

    .nav-buttons {
      display: flex;
      align-items: center;
      gap: 8px;
      justify-self: end;
      white-space: nowrap;
    }

    .user-name {
      font-size: 14px;
      color: rgba(255, 255, 255, 0.9);
      font-weight: 500;
      margin-right: 12px;
    }

    .nav-buttons button {
      color: white;
    }

    .nav-buttons button mat-icon {
      margin-right: 4px;
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
