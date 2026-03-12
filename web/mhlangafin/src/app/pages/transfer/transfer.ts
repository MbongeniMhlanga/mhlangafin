import { Component, inject, signal, OnInit, ChangeDetectionStrategy, computed } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Api } from '../../services/api';
import { AuthService } from '../../services/auth';
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
  private fb = inject(FormBuilder);
  private api = inject(Api);
  private authService = inject(AuthService);

  accounts = signal<any[]>([]);
  beneficiaries = signal<any[]>([]);
  isLoading = signal(false);
  isLoadingAccounts = signal(true);
  isLoadingBeneficiaries = signal(true);
  errorMessage = signal<string | null>(null);

  mainAccount = computed(() => this.accounts().find(a => a.isMain));
  showAddBeneficiary = signal(false);

  // Modal state
  showModal = signal(false);
  transactionId = signal<number | null>(null);
  lastAmount = signal<number>(0);
  lastToAccount = signal<string>('');

  transferForm = this.fb.nonNullable.group({
    fromAccountNumber: ['', [Validators.required]],
    toAccountNumber: ['', [Validators.required]],
    amount: [0, [Validators.required, Validators.min(0.01)]],
    beneficiaryReference: ['', [Validators.required]],
    senderReference: ['', [Validators.required]]
  });

  beneficiaryForm = this.fb.nonNullable.group({
    name: ['', [Validators.required]],
    accountNumber: ['', [Validators.required]],
    bankName: ['']
  });

  ngOnInit() {
    this.fetchAccounts();
    this.fetchBeneficiaries();
  }

  fetchAccounts() {
    this.api.getMyAccounts().subscribe({
      next: (data) => {
        this.accounts.set(data);
        const main = data.find((a: any) => a.isMain);
        if (main) this.transferForm.patchValue({ fromAccountNumber: main.accountNumber });
        this.isLoadingAccounts.set(false);
      },
      error: () => { this.isLoadingAccounts.set(false); }
    });
  }

  fetchBeneficiaries() {
    this.isLoadingBeneficiaries.set(true);
    this.api.getBeneficiaries().subscribe({
      next: (data) => {
        this.beneficiaries.set(data);
        this.isLoadingBeneficiaries.set(false);
      },
      error: () => { this.isLoadingBeneficiaries.set(false); }
    });
  }

  selectBeneficiary(ben: any) {
    this.transferForm.patchValue({ 
      toAccountNumber: ben.accountNumber,
      senderReference: ben.name,
      beneficiaryReference: this.authService.getUserInitialsAndSurname()
    });
  }

  saveBeneficiary() {
    if (this.beneficiaryForm.valid) {
      this.isLoading.set(true);
      this.api.addBeneficiary(this.beneficiaryForm.getRawValue()).subscribe({
        next: () => {
          this.fetchBeneficiaries();
          this.showAddBeneficiary.set(false);
          this.beneficiaryForm.reset();
          this.isLoading.set(false);
        },
        error: (err) => {
          this.errorMessage.set(err.error?.message || 'Failed to save beneficiary');
          this.isLoading.set(false);
        }
      });
    }
  }

  onSubmit() {
    if (this.transferForm.invalid) return;

    const { fromAccountNumber, toAccountNumber, amount, beneficiaryReference, senderReference } = this.transferForm.getRawValue();

    if (fromAccountNumber === toAccountNumber) {
      this.errorMessage.set('Source and destination accounts cannot be the same.');
      return;
    }

    this.isLoading.set(true);
    this.errorMessage.set(null);

    this.api.transfer({ 
      fromAccountNumber, 
      toAccountNumber, 
      amount: Number(amount),
      beneficiaryReference,
      senderReference
    }).subscribe({
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
          err?.error?.message || err?.error?.Message || 'Payment failed. Please try again.'
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

  logout() {
    this.authService.logout();
  }
}
