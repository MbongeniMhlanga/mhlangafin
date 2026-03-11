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

  onSubmit() {
    if (this.registerForm.valid) {
      this.isLoading.set(true);
      this.errorMessage.set(null);

      const { firstName, lastName, email, payloadPassword } = {
        firstName: this.registerForm.value.firstName!,
        lastName: this.registerForm.value.lastName!,
        email: this.registerForm.value.email!,
        payloadPassword: this.registerForm.value.password!
      };

      this.authService.register({
        firstName,
        lastName,
        email,
        password: payloadPassword
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
}
