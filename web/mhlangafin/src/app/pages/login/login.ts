import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../services/auth';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink],
  templateUrl: './login.html',
  styleUrls: ['./login.css']
})
export class Login {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);

  loginForm = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', Validators.required]
  });

  errorMessage = signal<string | null>(null);
  popupTitle = signal<string>('Login Required');
  popupMessage = signal<string>('Please complete the form before signing in.');
  showPopup = signal<boolean>(false);
  isLoading = signal<boolean>(false);
  showPassword = signal<boolean>(false);

  togglePasswordVisibility() {
    this.showPassword.update((current) => !current);
  }

  closePopup() {
    this.showPopup.set(false);
  }

  private openPopup(title: string, message: string) {
    this.popupTitle.set(title);
    this.popupMessage.set(message);
    this.showPopup.set(true);
  }

  isFieldInvalid(controlName: 'email' | 'password') {
    const control = this.loginForm.controls[controlName];
    return control.invalid && (control.touched || control.dirty);
  }

  getEmailErrorMessage(): string | null {
    const control = this.loginForm.controls.email;
    if (!control.touched && !control.dirty) return null;
    if (control.hasError('required')) return 'Email address is required.';
    if (control.hasError('email')) return 'Enter a valid email address.';
    return null;
  }

  getPasswordErrorMessage(): string | null {
    const control = this.loginForm.controls.password;
    if (!control.touched && !control.dirty) return null;
    if (control.hasError('required')) return 'Password is required.';
    return null;
  }

  onSubmit() {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();

      const missingFields: string[] = [];
      if (this.loginForm.controls.email.hasError('required')) missingFields.push('email address');
      if (this.loginForm.controls.password.hasError('required')) missingFields.push('password');

      if (missingFields.length) {
        this.errorMessage.set('Please fill in all required fields.');
        this.openPopup(
          'Missing Details',
          `Please enter your ${missingFields.join(' and ')} before signing in.`
        );
      } else {
        this.errorMessage.set('Please correct the highlighted fields.');
        this.openPopup('Invalid Details', 'Please enter a valid email address and password.');
      }
      return;
    }

    this.isLoading.set(true);
    this.errorMessage.set(null);
    this.authService.login(this.loginForm.getRawValue()).subscribe({
      next: () => {
        this.isLoading.set(false);
      },
      error: () => {
        this.isLoading.set(false);
        this.errorMessage.set('Invalid email or password');
        this.openPopup(
          'Incorrect Credentials',
          'The email address or password you entered is incorrect. Please try again.'
        );
      }
    });
  }
}
