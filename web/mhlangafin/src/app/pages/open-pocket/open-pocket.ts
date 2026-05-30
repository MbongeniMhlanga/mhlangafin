import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Api } from '../../services/api';
import { AuthService } from '../../services/auth';

@Component({
  selector: 'app-open-pocket',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink],
  templateUrl: './open-pocket.html',
  styleUrls: ['./open-pocket.css']
})
export class OpenPocketPage {
  private fb = inject(FormBuilder);
  private api = inject(Api);
  private authService = inject(AuthService);

  isLoading = signal<boolean>(false);
  error = signal<string | null>(null);
  successMessage = signal<string | null>(null);

  pocketForm = this.fb.nonNullable.group({
    accountName: ['', [Validators.required, Validators.minLength(2)]],
    initialBalance: [100, [Validators.required, Validators.min(100)]]
  });

  private getUserIdFromToken(): number {
    const token = this.authService.token();
    if (!token) return 0;

    try {
      const base64Url = token.split('.')[1];
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(atob(base64).split('').map((c) => {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
      }).join(''));

      const payload = JSON.parse(jsonPayload);
      const userIdStr = payload['nameid']
        || payload['sub']
        || payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];

      return parseInt(userIdStr, 10);
    } catch (e) {
      console.error('Token parsing error:', e);
      return 0;
    }
  }

  onSubmit() {
    if (this.pocketForm.invalid) {
      this.pocketForm.markAllAsTouched();
      this.error.set('Please complete the highlighted fields.');
      return;
    }

    const userId = this.getUserIdFromToken();
    if (!userId) {
      this.error.set('Could not parse User ID from token.');
      return;
    }

    this.isLoading.set(true);
    this.error.set(null);
    this.successMessage.set(null);

    const { accountName, initialBalance } = this.pocketForm.getRawValue();

    this.api.createAccount({
      userId,
      accountName,
      initialBalance
    }).subscribe({
      next: () => {
        this.isLoading.set(false);
        this.successMessage.set(`Pocket "${accountName}" opened successfully.`);
        this.pocketForm.reset({ accountName: '', initialBalance: 100 });
      },
      error: (err) => {
        this.isLoading.set(false);
        this.error.set(err?.error?.message || 'Failed to create pocket.');
      }
    });
  }
}
