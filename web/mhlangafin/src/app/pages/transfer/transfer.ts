import { Component, inject, signal, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Api } from '../../services/api';
import { SuccessModal } from '../../shared/success-modal/success-modal';

@Component({
  selector: 'app-transfer',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink, CommonModule, SuccessModal],
  templateUrl: './transfer.html',
  styleUrls: ['./transfer.css'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class Transfer implements OnInit {
  private fb  = inject(FormBuilder);
  private api = inject(Api);

  accounts          = signal<any[]>([]);
  isLoading         = signal(false);
  isLoadingAccounts = signal(true);
  errorMessage      = signal<string | null>(null);

  // Modal state
  showModal     = signal(false);
  transactionId = signal<number | null>(null);
  lastAmount    = signal<number>(0);
  lastToAccount = signal<string>('');

  transferForm = this.fb.nonNullable.group({
    fromAccountNumber: ['', [Validators.required]],
    toAccountNumber:   ['', [Validators.required]],
    amount:            [0,  [Validators.required, Validators.min(0.01)]]
  });

  ngOnInit() {
    this.api.getMyAccounts().subscribe({
      next:  (data) => { this.accounts.set(data); this.isLoadingAccounts.set(false); },
      error: ()     => { this.isLoadingAccounts.set(false); }
    });
  }

  onSubmit() {
    if (this.transferForm.invalid) return;

    const { fromAccountNumber, toAccountNumber, amount } = this.transferForm.getRawValue();

    if (fromAccountNumber === toAccountNumber) {
      this.errorMessage.set('Source and destination accounts cannot be the same.');
      return;
    }

    this.isLoading.set(true);
    this.errorMessage.set(null);

    this.api.transfer({ fromAccountNumber, toAccountNumber, amount: Number(amount) }).subscribe({
      next: (res) => {
        this.isLoading.set(false);

        // Store details for the modal
        this.transactionId.set(res.transactionId);
        this.lastAmount.set(Number(amount));
        this.lastToAccount.set(toAccountNumber);

        // Show modal and refresh balances
        this.showModal.set(true);
        this.api.getMyAccounts().subscribe(data => this.accounts.set(data));
      },
      error: (err) => {
        this.isLoading.set(false);
        this.errorMessage.set(
          err?.error?.message || err?.error?.Message || 'Transfer failed. Please try again.'
        );
      }
    });
  }

  onModalClose() {
    this.showModal.set(false);
    this.transferForm.reset({ fromAccountNumber: '', toAccountNumber: '', amount: 0 });
  }

  onNewTransfer() {
    this.showModal.set(false);
    this.transferForm.reset({ fromAccountNumber: '', toAccountNumber: '', amount: 0 });
  }
}
