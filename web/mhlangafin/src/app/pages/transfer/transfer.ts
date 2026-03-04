import { Component, inject, signal, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Api } from '../../services/api';

@Component({
    selector: 'app-transfer',
    standalone: true,
    imports: [ReactiveFormsModule, RouterLink, CommonModule],
    templateUrl: './transfer.html',
    styleUrls: ['./transfer.css'],
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class Transfer implements OnInit {
    private fb = inject(FormBuilder);
    private api = inject(Api);

    accounts = signal<any[]>([]);
    isLoading = signal(false);
    isLoadingAccounts = signal(true);
    successMessage = signal<string | null>(null);
    errorMessage = signal<string | null>(null);

    transferForm = this.fb.nonNullable.group({
        fromAccountId: [0, [Validators.required, Validators.min(1)]],
        toAccountId: ['', [Validators.required]],
        amount: [0, [Validators.required, Validators.min(0.01)]]
    });

    ngOnInit() {
        this.api.getMyAccounts().subscribe({
            next: (data) => {
                this.accounts.set(data);
                this.isLoadingAccounts.set(false);
            },
            error: () => {
                this.isLoadingAccounts.set(false);
            }
        });
    }

    onSubmit() {
        if (this.transferForm.invalid) return;

        const { fromAccountId, toAccountId, amount } = this.transferForm.getRawValue();

        if (String(fromAccountId) === String(toAccountId)) {
            this.errorMessage.set('Source and destination accounts cannot be the same.');
            return;
        }

        this.isLoading.set(true);
        this.errorMessage.set(null);
        this.successMessage.set(null);

        this.api.transfer({
            fromAccountId: Number(fromAccountId),
            toAccountId: Number(toAccountId),
            amount: Number(amount)
        }).subscribe({
            next: (res) => {
                this.isLoading.set(false);
                this.successMessage.set(`✅ Transfer successful! Transaction ID: #${res.transactionId}`);
                this.transferForm.reset({ fromAccountId: 0, toAccountId: '', amount: 0 });
                // Refresh balances
                this.api.getMyAccounts().subscribe(data => this.accounts.set(data));
            },
            error: (err) => {
                this.isLoading.set(false);
                this.errorMessage.set(err?.error?.message || err?.error?.Message || 'Transfer failed. Please try again.');
            }
        });
    }
}
