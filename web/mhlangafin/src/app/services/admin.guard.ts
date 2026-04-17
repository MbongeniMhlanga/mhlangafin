import { Injectable, inject } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { AuthService } from './auth';

@Injectable({
  providedIn: 'root'
})
export class AdminGuard implements CanActivate {
  private authService = inject(AuthService);
  private router = inject(Router);

  canActivate(): boolean {
    const user = this.authService.user();
    if (user && user.role === 'Admin') {
      return true;
    }

    // Fallback: check token directly if user signal not ready
    const token = this.authService.token();
    if (token) {
      try {
        const base64Url = token.split('.')[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(atob(base64).split('').map(function (c) {
          return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));

        const payload = JSON.parse(jsonPayload);
        const role = payload['role'] || payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] || payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/role'];
        if (role === 'Admin') {
          return true;
        }
      } catch (e) {
        console.error('Error decoding token in guard', e);
      }
    }

    this.router.navigate(['/dashboard']);
    return false;
  }
}