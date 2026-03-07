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

  createAccountForm = this.fb.nonNullable.group({
    accountName: ['', [Validators.required, Validators.minLength(2)]],
    initialBalance: [0.01, [Validators.required, Validators.min(0.01)]]
  });

  // Transaction History State
  selectedAccount = signal<any>(null);
  transactionHistory = signal<any>(null);
  isHistoryLoading = signal<boolean>(false);
  historyError = signal<string | null>(null);

  // Statement State
  statementForm = this.fb.nonNullable.group({
    startDate: ['', Validators.required],
    endDate: ['', Validators.required]
  });
  isStatementLoading = signal<boolean>(false);
  statementError = signal<string | null>(null);

  // Since backend requires UserId for Create Account, we parse the JWT!
  // It's technically better to read it on the server, but doing it fast here:
  private getUserIdFromToken(): number {
    const token = this.authService.token();
    if (!token) return 0;
    try {
      // Decode the JWT payload using base64 decoding (handling URL-safe base64)
      const base64Url = token.split('.')[1];
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(atob(base64).split('').map(function (c) {
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
        accountName: this.createAccountForm.getRawValue().accountName,
        initialBalance: this.createAccountForm.getRawValue().initialBalance
      }).subscribe({
        next: () => {
          this.createAccountForm.reset({ accountName: '', initialBalance: 0.01 });
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

  scrollToForm() {
    const element = document.getElementById('openAccountSection');
    if (element) {
      element.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }

  // Transaction History Methods
  viewTransactionHistory(account: any) {
    this.selectedAccount.set(account);
    this.transactionHistory.set(null);
    this.historyError.set(null);
    this.isHistoryLoading.set(true);

    this.api.getTransactionHistory(account.accountNumber).subscribe({
      next: (data) => {
        this.transactionHistory.set(data);
        this.isHistoryLoading.set(false);
      },
      error: (err) => {
        this.historyError.set('Failed to load transaction history.');
        this.isHistoryLoading.set(false);
      }
    });
  }

  closeTransactionHistory() {
    this.selectedAccount.set(null);
    this.transactionHistory.set(null);
    this.historyError.set(null);
  }

  // Statement Methods
  downloadStatement() {
    if (this.statementForm.valid && this.selectedAccount()) {
      const startDate = new Date(this.statementForm.getRawValue().startDate);
      const endDate = new Date(this.statementForm.getRawValue().endDate);

      if (startDate > endDate) {
        this.statementError.set('Start date must be before end date.');
        return;
      }

      this.isStatementLoading.set(true);
      this.statementError.set(null);

      this.api.downloadStatement(
        this.selectedAccount().accountNumber,
        startDate,
        endDate,
        'PDF'
      ).subscribe({
        next: (blob) => {
          // Create download link for text file
          const downloadUrl = window.URL.createObjectURL(blob);
          const link = document.createElement('a');
          link.href = downloadUrl;
          const fileName = `statement_${this.selectedAccount().accountNumber}_${startDate.toISOString().split('T')[0]}_to_${endDate.toISOString().split('T')[0]}.txt`;
          link.download = fileName;
          link.click();
          
          // Clean up
          window.URL.revokeObjectURL(downloadUrl);
          this.isStatementLoading.set(false);
        },
        error: (err) => {
          this.statementError.set('Failed to download statement.');
          this.isStatementLoading.set(false);
        }
      });
    }
  }

  closeStatementModal() {
    this.selectedAccount.set(null);
    this.statementForm.reset();
    this.statementError.set(null);
  }
}
