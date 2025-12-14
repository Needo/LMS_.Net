import { Routes } from '@angular/router';
import { MainLayoutComponent } from './components/main-layout/main-layout.component';
import { AdminComponent } from './components/admin/admin.component';

export const routes: Routes = [
  { path: '', component: MainLayoutComponent },
  { path: 'admin', component: AdminComponent },
  { path: '**', redirectTo: '' }
];