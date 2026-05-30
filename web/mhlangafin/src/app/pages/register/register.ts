import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../services/auth';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink],
  templateUrl: './register.html',
  styleUrls: ['./register.css']
})
export class Register {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);

  registerForm = this.fb.nonNullable.group({
    firstName: ['', [Validators.required, Validators.minLength(2)]],
    lastName: ['', [Validators.required, Validators.minLength(2)]],
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
    confirmPassword: ['', [Validators.required]]
  }, {
    validators: (group) => {
      const pass = group.get('password')?.value;
      const confirm = group.get('confirmPassword')?.value;
      return pass === confirm ? null : { notMatched: true };
    }
  });

  errorMessage = signal<string | null>(null);
  isLoading = signal<boolean>(false);
  showPassword = signal<boolean>(false);
  showConfirmPassword = signal<boolean>(false);

  togglePasswordVisibility() {
    this.showPassword.update((current) => !current);
  }

  toggleConfirmPasswordVisibility() {
    this.showConfirmPassword.update((current) => !current);
  }

  isFieldInvalid(controlName: 'firstName' | 'lastName' | 'email' | 'password' | 'confirmPassword') {
    const control = this.registerForm.controls[controlName];
    return control.invalid && (control.touched || control.dirty);
  }

  getFirstNameErrorMessage(): string | null {
    const control = this.registerForm.controls.firstName;
    if (!control.touched && !control.dirty) return null;
    if (control.hasError('required')) return 'First name is required.';
    if (control.hasError('minlength')) return 'First name must be at least 2 characters.';
    return null;
  }

  getLastNameErrorMessage(): string | null {
    const control = this.registerForm.controls.lastName;
    if (!control.touched && !control.dirty) return null;
    if (control.hasError('required')) return 'Last name is required.';
    if (control.hasError('minlength')) return 'Last name must be at least 2 characters.';
    return null;
  }

  getEmailErrorMessage(): string | null {
    const control = this.registerForm.controls.email;
    if (!control.touched && !control.dirty) return null;
    if (control.hasError('required')) return 'Email address is required.';
    if (control.hasError('email')) return 'Enter a valid email address.';
    return null;
  }

  getPasswordErrorMessage(): string | null {
    const control = this.registerForm.controls.password;
    if (!control.touched && !control.dirty) return null;
    if (control.hasError('required')) return 'Password is required.';
    if (control.hasError('minlength')) return 'Use at least 6 characters.';
    return null;
  }

  getConfirmPasswordErrorMessage(): string | null {
    const control = this.registerForm.controls.confirmPassword;
    if (!control.touched && !control.dirty) return null;
    if (control.hasError('required')) return 'Please confirm your password.';
    if (this.registerForm.hasError('notMatched')) return 'Passwords do not match.';
    return null;
  }

  getPasswordMatchMessage(): { text: string; valid: boolean } | null {
    const password = this.registerForm.controls.password.value;
    const confirmPassword = this.registerForm.controls.confirmPassword.value;

    if (!password || !confirmPassword) return null;

    const valid = password === confirmPassword;
    return {
      valid,
      text: valid ? 'Passwords match' : 'Passwords do not match'
    };
  }

  onSubmit() {
    if (this.registerForm.invalid) {
      this.registerForm.markAllAsTouched();
      this.errorMessage.set('Please complete the highlighted fields.');
      return;
    }

    this.isLoading.set(true);
    this.errorMessage.set(null);

    const { firstName, lastName, email, password } = this.registerForm.getRawValue();

    this.authService.register({
      firstName,
      lastName,
      email,
      password
    }).subscribe({
      next: () => {
        this.isLoading.set(false);
        this.router.navigate(['/login']);
      },
      error: (err) => {
        this.isLoading.set(false);
        this.errorMessage.set(err?.error?.message || 'Failed to register. Email may already be in use.');
      }
    });
  }
}
