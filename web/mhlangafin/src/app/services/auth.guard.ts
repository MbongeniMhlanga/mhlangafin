import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from './auth';

export const authGuard = () => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }

  // Redirect to login if not authenticated
  return router.parseUrl('/login');
};
