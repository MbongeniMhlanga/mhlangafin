import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root',
})
export class AdminService {
  private http = inject(HttpClient);
  private apiUrl = `${environment.apiUrl}/Admin`;

  // Users
  getUsers(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/users`);
  }

  updateUserStatus(userId: number, status: string): Observable<any> {
    return this.http.patch<any>(`${this.apiUrl}/users/${userId}/status`, { status });
  }

  resetUserPassword(userId: number, newPassword: string): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/users/${userId}/reset-password`, { newPassword });
  }

  // Accounts
  updateAccountStatus(accountId: number, status: string): Observable<any> {
    return this.http.patch<any>(`${this.apiUrl}/accounts/${accountId}/status`, { status });
  }

  // Transactions
  getTransactions(status?: string): Observable<any[]> {
    const params: any = {};
    if (status) params.status = status;
    return this.http.get<any[]>(`${this.apiUrl}/transactions`, { params });
  }

  approveTransaction(transactionId: number, note?: string): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/transactions/${transactionId}/approve`, { note });
  }

  rejectTransaction(transactionId: number, note?: string): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/transactions/${transactionId}/reject`, { note });
  }

  // Stats
  getStats(): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/stats`);
  }
}