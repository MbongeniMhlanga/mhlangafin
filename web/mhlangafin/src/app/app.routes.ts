import { Routes } from '@angular/router';
import { authGuard } from './services/auth.guard';
import { AdminGuard } from './services/admin.guard';

export const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: 'login', loadComponent: () => import('./pages/login/login').then(m => m.Login) },
  { path: 'register', loadComponent: () => import('./pages/register/register').then(m => m.Register) },
  { path: 'dashboard', loadComponent: () => import('./pages/dashboard/dashboard').then(m => m.Dashboard), canActivate: [authGuard] },
  { path: 'transfer', loadComponent: () => import('./pages/transfer/transfer').then(m => m.Transfer), canActivate: [authGuard] },
  { path: 'digital-card', loadComponent: () => import('./pages/digital-card/digital-card').then(m => m.DigitalCardPage), canActivate: [authGuard] },
  { path: 'admin', loadComponent: () => import('./pages/admin-dashboard/admin-dashboard').then(m => m.AdminDashboard), canActivate: [AdminGuard] },
  { path: 'admin/users', loadComponent: () => import('./pages/admin-users/admin-users').then(m => m.AdminUsers), canActivate: [AdminGuard] },
  { path: 'admin/transactions', loadComponent: () => import('./pages/admin-transactions/admin-transactions').then(m => m.AdminTransactions), canActivate: [AdminGuard] },
  { path: '**', redirectTo: 'dashboard' }
];
