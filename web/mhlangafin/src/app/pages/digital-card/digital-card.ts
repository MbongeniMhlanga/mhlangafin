import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { Api } from '../../services/api';
import { AuthService } from '../../services/auth';

@Component({
  selector: 'app-digital-card-page',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './digital-card.html'
})
export class DigitalCardPage implements OnInit {
  private api = inject(Api);
  private authService = inject(AuthService);

  accounts = signal<any[]>([]);
  isLoading = signal<boolean>(true);
  error = signal<string | null>(null);
  showCardDetails = signal<boolean>(false);

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
        this.error.set('Failed to load accounts.');
        this.isLoading.set(false);
      }
    });
  }

  toggleCardDetails() {
    this.showCardDetails.update(v => !v);
  }

  getPrimaryAccountNumber(): string {
    const accs = this.accounts();
    if (accs.length > 0) {
      return accs[0].accountNumber;
    }
    return 'FN-PENDING-CARD';
  }

  getUserName(): string {
    const token = this.authService.token();
    if (!token) return 'USER';
    try {
      const base64Url = token.split('.')[1];
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
      const payload = JSON.parse(atob(base64));
      
      // .NET Identity typically maps ClaimTypes.Name to this long URI in the token
      return payload['unique_name'] 
        || payload['name'] 
        || payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']
        || payload['sub'] 
        || 'MEMBER';
    } catch (e) {
      return 'MEMBER';
    }
  }

  getInitialAndSurname(): string {
    const fullName = this.getUserName();
    const parts = fullName.split(' ').filter(p => p.length > 0);
    if (parts.length >= 2) {
      const initial = parts[0][0].toUpperCase();
      const surname = parts[parts.length - 1];
      return `${initial}. ${surname}`;
    }
    return fullName;
  }

  getUserInitials(): string {
    const name = this.getUserName();
    return name.split(' ').map(n => n[0]).join('').toUpperCase().substring(0, 2);
  }

  logout() {
    this.authService.logout();
  }
}
