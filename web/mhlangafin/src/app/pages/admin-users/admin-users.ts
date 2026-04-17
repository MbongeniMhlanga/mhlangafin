import { Component, inject, signal, OnInit } from '@angular/core';
import { AdminService } from '../../services/admin';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';

@Component({
  selector: 'app-admin-users',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './admin-users.html',
  styleUrls: ['./admin-users.css']
})
export class AdminUsers implements OnInit {
  private adminService = inject(AdminService);
  private router = inject(Router);

  users = signal<any[]>([]);
  isLoading = signal<boolean>(true);
  error = signal<string | null>(null);

  ngOnInit() {
    this.loadUsers();
  }

  loadUsers() {
    this.isLoading.set(true);
    this.error.set(null);
    this.adminService.getUsers().subscribe({
      next: (data) => {
        this.users.set(data);
        this.isLoading.set(false);
      },
      error: (err) => {
        this.error.set('Failed to load users');
        this.isLoading.set(false);
        console.error('Error loading users:', err);
      }
    });
  }

  toggleUserStatus(user: any) {
    const newStatus = user.status === 'Active' ? 'Blocked' : 'Active';
    this.adminService.updateUserStatus(user.id, newStatus).subscribe({
      next: () => {
        user.status = newStatus;
        this.users.update(users => [...users]); // Trigger change detection
      },
      error: (err) => {
        console.error('Error updating user status:', err);
        alert('Failed to update user status');
      }
    });
  }

  resetPassword(user: any) {
    const newPassword = prompt('Enter new password:');
    if (newPassword) {
      this.adminService.resetUserPassword(user.id, newPassword).subscribe({
        next: () => {
          alert('Password reset successfully');
        },
        error: (err) => {
          console.error('Error resetting password:', err);
          alert('Failed to reset password');
        }
      });
    }
  }

  logout() {
    // Clear any stored auth tokens
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    // Navigate to login page
    this.router.navigate(['/login']);
  }
}
