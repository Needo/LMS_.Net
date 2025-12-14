import { Component } from '@angular/core';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [MatToolbarModule, MatButtonModule, MatIconModule, RouterModule],
  template: `
    <mat-toolbar color="primary">
      <span>Learning Management System</span>
      <span class="spacer"></span>
      <button mat-button routerLink="/admin">
        <mat-icon>settings</mat-icon>
        Admin
      </button>
    </mat-toolbar>
  `,
  styles: ['.spacer { flex: 1 1 auto; }']
})
export class HeaderComponent {}
