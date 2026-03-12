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

  transfer(payload: { fromAccountNumber: string, toAccountNumber: string, amount: number, beneficiaryReference?: string, senderReference?: string }): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/Transactions/transfer`, payload);
  }

  internalTransfer(payload: { fromAccountId: number, toAccountId: number, amount: number }): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/Transactions/internal-transfer`, payload);
  }

  // Beneficiaries
  getBeneficiaries(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/Beneficiaries`);
  }

  addBeneficiary(payload: { name: string, accountNumber: string, bankName?: string }): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/Beneficiaries`, payload);
  }

  deleteBeneficiary(id: number): Observable<any> {
    return this.http.delete<any>(`${this.apiUrl}/Beneficiaries/${id}`);
  }

  // Transaction History
  getTransactionHistory(accountNumber: string, startDate?: Date, endDate?: Date, page: number = 1, pageSize: number = 20): Observable<any> {
    const params: any = { accountNumber, page, pageSize };
    if (startDate) params.startDate = startDate.toISOString();
    if (endDate) params.endDate = endDate.toISOString();
    return this.http.get<any>(`${this.apiUrl}/Transactions/history`, { params });
  }

  // Statements
  generateStatement(accountNumber: string, startDate: Date, endDate: Date): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/Transactions/statement`, {
      accountNumber,
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString()
    });
  }

  downloadStatement(accountNumber: string, startDate: Date, endDate: Date, format: string = 'PDF'): Observable<Blob> {
    return this.http.post(`${this.apiUrl}/Transactions/statement/download`, {
      accountNumber,
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString()
    }, {
      params: { format },
      responseType: 'blob'
    }) as Observable<Blob>;
  }
}
