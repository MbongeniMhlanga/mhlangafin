import { CommonModule } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';

import { Api } from '../../services/api';
import { AuthService } from '../../services/auth';

@Component({
  selector: 'app-account-page',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './account.html',
  styleUrls: ['./account.css'],
})
export class AccountPage implements OnInit {
  private api = inject(Api);
  readonly authService = inject(AuthService);
  private fb = inject(FormBuilder);

  profileForm = this.fb.nonNullable.group({
    firstName: ['', [Validators.required, Validators.minLength(2)]],
    lastName: ['', [Validators.required, Validators.minLength(2)]],
    email: ['', [Validators.required, Validators.email]]
  });

  passwordForm = this.fb.nonNullable.group({
    currentPassword: ['', [Validators.required]],
    newPassword: ['', [Validators.required, Validators.minLength(6)]],
    confirmPassword: ['', [Validators.required]]
  }, {
    validators: (group) => {
      const newPassword = group.get('newPassword')?.value;
      const confirmPassword = group.get('confirmPassword')?.value;
      return newPassword === confirmPassword ? null : { notMatched: true };
    }
  });

  isLoadingProfile = signal<boolean>(true);
  isSavingProfile = signal<boolean>(false);
  isChangingPassword = signal<boolean>(false);
  successMessage = signal<string | null>(null);
  errorMessage = signal<string | null>(null);

  showCurrentPassword = signal<boolean>(false);
  showNewPassword = signal<boolean>(false);
  showConfirmPassword = signal<boolean>(false);

  ngOnInit(): void {
    this.loadProfile();
  }

  loadProfile(): void {
    this.isLoadingProfile.set(true);
    this.errorMessage.set(null);

    this.api.getMyProfile().subscribe({
      next: (profile) => {
        this.profileForm.patchValue({
          firstName: profile.firstName ?? '',
          lastName: profile.lastName ?? '',
          email: profile.email ?? ''
        });
        this.authService.user.set({
          id: profile.userId,
          firstName: profile.firstName,
          fullName: `${profile.firstName} ${profile.lastName}`,
          email: profile.email,
          role: profile.role
        });
        this.isLoadingProfile.set(false);
      },
      error: () => {
        this.errorMessage.set('We could not load your profile details.');
        this.isLoadingProfile.set(false);
      }
    });
  }

  saveProfile(): void {
    if (this.profileForm.invalid) {
      this.profileForm.markAllAsTouched();
      this.errorMessage.set('Please fix the highlighted profile fields.');
      return;
    }

    this.isSavingProfile.set(true);
    this.errorMessage.set(null);
    this.successMessage.set(null);

    this.api.updateMyProfile(this.profileForm.getRawValue()).subscribe({
      next: (profile) => {
        this.authService.user.set({
          id: profile.userId,
          firstName: profile.firstName,
          fullName: `${profile.firstName} ${profile.lastName}`,
          email: profile.email,
          role: profile.role
        });
        this.successMessage.set('Your profile was updated successfully.');
        this.isSavingProfile.set(false);
      },
      error: (err) => {
        this.errorMessage.set(err?.error?.message || 'Unable to update your profile right now.');
        this.isSavingProfile.set(false);
      }
    });
  }

  savePassword(): void {
    if (this.passwordForm.invalid) {
      this.passwordForm.markAllAsTouched();
      this.errorMessage.set('Please complete the password fields.');
      return;
    }

    this.isChangingPassword.set(true);
    this.errorMessage.set(null);
    this.successMessage.set(null);

    const { currentPassword, newPassword } = this.passwordForm.getRawValue();

    this.api.changeMyPassword({ currentPassword, newPassword }).subscribe({
      next: () => {
        this.passwordForm.reset();
        this.successMessage.set('Your password has been updated.');
        this.isChangingPassword.set(false);
      },
      error: (err) => {
        this.errorMessage.set(err?.error?.message || 'Unable to update your password right now.');
        this.isChangingPassword.set(false);
      }
    });
  }

  toggleCurrentPasswordVisibility(): void {
    this.showCurrentPassword.update((current) => !current);
  }

  toggleNewPasswordVisibility(): void {
    this.showNewPassword.update((current) => !current);
  }

  toggleConfirmPasswordVisibility(): void {
    this.showConfirmPassword.update((current) => !current);
  }

  getProfileErrorMessage(controlName: 'firstName' | 'lastName' | 'email'): string | null {
    const control = this.profileForm.controls[controlName];
    if (!control.touched && !control.dirty) return null;
    if (control.hasError('required')) return `${this.getLabel(controlName)} is required.`;
    if (control.hasError('minlength')) return `${this.getLabel(controlName)} must be at least 2 characters.`;
    if (control.hasError('email')) return 'Enter a valid email address.';
    return null;
  }

  getPasswordErrorMessage(controlName: 'currentPassword' | 'newPassword' | 'confirmPassword'): string | null {
    const control = this.passwordForm.controls[controlName];
    if (!control.touched && !control.dirty) return null;
    if (control.hasError('required')) {
      if (controlName === 'currentPassword') return 'Current password is required.';
      if (controlName === 'newPassword') return 'New password is required.';
      return 'Please confirm your new password.';
    }
    if (controlName === 'newPassword' && control.hasError('minlength')) {
      return 'Use at least 6 characters.';
    }
    if (controlName === 'confirmPassword' && this.passwordForm.hasError('notMatched')) {
      return 'Passwords do not match.';
    }
    return null;
  }

  getPasswordMatchMessage(): { text: string; valid: boolean } | null {
    const newPassword = this.passwordForm.controls.newPassword.value;
    const confirmPassword = this.passwordForm.controls.confirmPassword.value;

    if (!newPassword || !confirmPassword) return null;

    const valid = newPassword === confirmPassword;
    return {
      valid,
      text: valid ? 'Passwords match' : 'Passwords do not match'
    };
  }

  private getLabel(controlName: 'firstName' | 'lastName' | 'email'): string {
    switch (controlName) {
      case 'firstName':
        return 'First name';
      case 'lastName':
        return 'Last name';
      case 'email':
        return 'Email address';
    }
  }

  displayName(): string {
    const profile = this.profileForm.getRawValue();
    return `${profile.firstName || 'Your'} ${profile.lastName || 'Account'}`.trim();
  }

  initials(): string {
    const profile = this.profileForm.getRawValue();
    const first = profile.firstName?.trim().charAt(0) || 'M';
    const last = profile.lastName?.trim().charAt(0) || 'F';
    return `${first}${last}`.toUpperCase();
  }
}
