import { Component, inject, signal, OnInit } from '@angular/core';
import { AdminService } from '../../services/admin';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './admin-dashboard.html',
  styleUrls: ['./admin-dashboard.css']
})
export class AdminDashboard implements OnInit {
  private adminService = inject(AdminService);
  private router = inject(Router);

  stats = signal<any>(null);
  isLoading = signal<boolean>(true);
  error = signal<string | null>(null);

  ngOnInit() {
    this.loadStats();
  }

  loadStats() {
    this.isLoading.set(true);
    this.error.set(null);
    this.adminService.getStats().subscribe({
      next: (data) => {
        this.stats.set(data);
        this.isLoading.set(false);
      },
      error: (err) => {
        this.error.set('Failed to load admin statistics');
        this.isLoading.set(false);
        console.error('Error loading stats:', err);
      }
    });
  }

  logout() {
    // Clear any stored auth tokens
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    // Navigate to login page
    this.router.navigate(['/login']);
  }
}