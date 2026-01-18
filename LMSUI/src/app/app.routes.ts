import { Routes } from '@angular/router';
import { MainLayoutComponent } from './components/main-layout/main-layout.component';
import { AdminComponent } from './components/admin/admin.component';
import { LoginComponent } from './components/login/login.component';
import { authGuard } from './guards/auth.guard';
import { adminGuard } from './guards/admin.guard';

// TEMPORARY: Comment out guards for testing
export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { 
    path: '', 
    component: MainLayoutComponent,
    // canActivate: [authGuard]  // TEMPORARILY DISABLED FOR TESTING
  },
  { 
    path: 'admin', 
    component: AdminComponent,
    // canActivate: [authGuard, adminGuard]  // TEMPORARILY DISABLED FOR TESTING
  },
  { path: '**', redirectTo: '' }
];
