import { Injectable, signal, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { tap, catchError } from 'rxjs/operators';
import { of } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private http = inject(HttpClient);
  private router = inject(Router);

  private apiUrl = 'http://localhost:5075/api/Auth';

  // Use signal for auth state
  token = signal<string | null>(localStorage.getItem('token'));
  isAuthenticated = signal<boolean>(!!localStorage.getItem('token'));

  // Derived user information from token
  user = signal<any>(null);

  constructor() {
    this.decodeToken();
  }

  private decodeToken() {
    const currentToken = this.token();
    if (!currentToken) {
      this.user.set(null);
      return;
    }
    try {
      const base64Url = currentToken.split('.')[1];
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(atob(base64).split('').map(function (c) {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
      }).join(''));

      const payload = JSON.parse(jsonPayload);

      // Map standard JWT claims to readable keys
      this.user.set({
        id: payload['nameid'] || payload['sub'],
        fullName: payload['unique_name'] || payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'],
        firstName: payload['given_name'] || payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname'],
        email: payload['email'] || payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'],
        role: payload['role'] || payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/role']
      });
    } catch (e) {
      console.error('Error decoding token', e);
      this.user.set(null);
    }
  }

  getUserInitialsAndSurname(): string {
    const userData = this.user();
    if (!userData || !userData.fullName) return 'TRANSFER';

    const names = userData.fullName.split(' ');
    if (names.length < 2) return names[0].toUpperCase();

    const initial = names[0].charAt(0).toUpperCase();
    const surname = names[names.length - 1];
    return `${initial} ${surname}`;
  }

  login(credentials: any) {
    return this.http.post<any>(`${this.apiUrl}/login`, credentials).pipe(
      tap(res => {
        if (res && res.token) {
          localStorage.setItem('token', res.token);
          this.token.set(res.token);
          this.decodeToken();
          this.isAuthenticated.set(true);
          this.router.navigate(['/dashboard']);
        }
      })
    );
  }

  register(userData: any) {
    return this.http.post<any>(`${this.apiUrl}/register`, userData);
  }

  logout() {
    localStorage.removeItem('token');
    this.token.set(null);
    this.isAuthenticated.set(false);
    this.router.navigate(['/login']);
  }
}
