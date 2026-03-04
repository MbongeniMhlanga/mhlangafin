import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class Api {
  private http = inject(HttpClient);
  private apiUrl = 'http://localhost:5075/api';

  // Accounts
  getMyAccounts(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/Accounts/my`);
  }

  createAccount(payload: { userId: number, accountName: string, initialBalance: number }): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/Accounts`, payload);
  }

  transfer(payload: { fromAccountNumber: string, toAccountNumber: string, amount: number }): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/Transactions/transfer`, payload);
  }
}
