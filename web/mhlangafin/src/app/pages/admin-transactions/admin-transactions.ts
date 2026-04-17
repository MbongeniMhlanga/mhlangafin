import { Component, inject, signal, OnInit } from '@angular/core';
import { AdminService } from '../../services/admin';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-admin-transactions',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './admin-transactions.html',
  styleUrls: ['./admin-transactions.css']
})
export class AdminTransactions implements OnInit {
  private adminService = inject(AdminService);

  transactions = signal<any[]>([]);
  isLoading = signal<boolean>(true);
  error = signal<string | null>(null);
  filterStatus = signal<string>('');

  ngOnInit() {
    this.loadTransactions();
  }

  loadTransactions() {
    this.isLoading.set(true);
    this.error.set(null);
    this.adminService.getTransactions(this.filterStatus() || undefined).subscribe({
      next: (data) => {
        this.transactions.set(data);
        this.isLoading.set(false);
      },
      error: (err) => {
        this.error.set('Failed to load transactions');
        this.isLoading.set(false);
        console.error('Error loading transactions:', err);
      }
    });
  }

  onFilterChange(event: Event) {
    const target = event.target as HTMLSelectElement;
    const status = target.value;
    this.filterStatus.set(status);
    this.loadTransactions();
  }

  approveTransaction(transaction: any) {
    const note = prompt('Approval note (optional):');
    this.adminService.approveTransaction(transaction.id, note || undefined).subscribe({
      next: () => {
        transaction.status = 'Approved';
        this.transactions.update(transactions => [...transactions]);
      },
      error: (err) => {
        console.error('Error approving transaction:', err);
        alert('Failed to approve transaction');
      }
    });
  }

  rejectTransaction(transaction: any) {
    const note = prompt('Rejection note (optional):');
    this.adminService.rejectTransaction(transaction.id, note || undefined).subscribe({
      next: () => {
        transaction.status = 'Rejected';
        this.transactions.update(transactions => [...transactions]);
      },
      error: (err) => {
        console.error('Error rejecting transaction:', err);
        alert('Failed to reject transaction');
      }
    });
  }
}