import { Component, inject, signal, OnInit } from '@angular/core';
import { AuthService } from '../../services/auth';
import { Api } from '../../services/api';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule, RouterLink],
  templateUrl: './dashboard.html',
  styleUrls: ['./dashboard.css']
})
export class Dashboard implements OnInit {
  authService = inject(AuthService);
  private api = inject(Api);
  private fb = inject(FormBuilder);

  accounts = signal<any[]>([]);
  isLoading = signal<boolean>(true);
  error = signal<string | null>(null);

  // Quick form for creating an account (hardcode initial balances to 0 or allow input)
  createAccountForm = this.fb.nonNullable.group({
    accountNumber: ['', [Validators.required, Validators.minLength(5)]],
    initialBalance: [0.01, [Validators.required, Validators.min(0.01)]] // Must be > 0.01 based on backend validation
  });

  // Since backend requires UserId for Create Account, we parse the JWT!
  // It's technically better to read it on the server, but doing it fast here:
  private getUserIdFromToken(): number {
    const token = this.authService.token();
    if (!token) return 0;
    try {
      // Decode the JWT payload using base64 decoding (handling URL-safe base64)
      const base64Url = token.split('.')[1];
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
          return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
      }).join(''));

      const payload = JSON.parse(jsonPayload);
      
      // JWT libraries map ClaimTypes in different ways (.NET typically uses generic 'nameid' or the full schema)
      const userIdStr = payload['nameid'] 
                     || payload['sub'] 
                     || payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
                     
      return parseInt(userIdStr, 10);
    } catch (e) {
      console.error('Token parsing error:', e);
      return 0;
    }
  }

  ngOnInit() {
    this.fetchAccounts();
  }

  fetchAccounts() {
    this.isLoading.set(true);
    this.api.getMyAccounts().subscribe({
      next: (data) => {
        this.accounts.set(data);
        this.isLoading.set(false);
      },
      error: (err) => {
        this.error.set('Failed to load accounts. Ensure backend is running.');
        this.isLoading.set(false);
      }
    });
  }

  createAccount() {
    if (this.createAccountForm.valid) {
      const userId = this.getUserIdFromToken();
      if (!userId) {
        this.error.set('Could not parse User ID from token.');
        return;
      }

      this.api.createAccount({
        userId: userId,
        accountNumber: this.createAccountForm.getRawValue().accountNumber,
        initialBalance: this.createAccountForm.getRawValue().initialBalance
      }).subscribe({
        next: () => {
          this.createAccountForm.reset({ accountNumber: '', initialBalance: 0.01 });
          this.fetchAccounts(); // refresh list
        },
        error: (err) => {
          this.error.set(err.message || 'Failed to create account.');
        }
      });
    }
  }

  logout() {
    this.authService.logout();
  }
}
