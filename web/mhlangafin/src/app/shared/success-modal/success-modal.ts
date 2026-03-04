import { Component, input, output, ChangeDetectionStrategy } from '@angular/core';
import { CommonModule, DecimalPipe } from '@angular/common';

@Component({
  selector: 'app-success-modal',
  standalone: true,
  imports: [CommonModule, DecimalPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (visible()) {
      <!-- Backdrop -->
      <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
           role="dialog" aria-modal="true" [attr.aria-labelledby]="'modal-title'">

        <!-- Dark overlay -->
        <div class="absolute inset-0 bg-gray-900/60 backdrop-blur-sm" (click)="close.emit()"></div>

        <!-- Modal card -->
        <div class="relative bg-white rounded-2xl shadow-2xl max-w-sm w-full p-8 text-center animate-in">

          <!-- Green check circle -->
          <div class="mx-auto mb-5 flex items-center justify-center w-20 h-20 rounded-full bg-green-100">
            <svg class="w-10 h-10 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7"/>
            </svg>
          </div>

          <h2 id="modal-title" class="text-2xl font-bold text-gray-900 mb-2">Transfer Successful</h2>
          <p class="text-gray-500 text-sm mb-6">Your funds have been securely sent.</p>

          <!-- Transaction detail -->
          <div class="bg-gray-50 rounded-xl px-6 py-4 mb-6 text-left space-y-3 border border-gray-100">
            <div class="flex justify-between text-sm">
              <span class="text-gray-500 font-medium">Transaction ID</span>
              <span class="font-mono font-semibold text-gray-800">#{{ transactionId() }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-500 font-medium">Amount</span>
              <span class="font-semibold text-gray-800">R{{ amount() | number:'1.2-2' }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-500 font-medium">To Account</span>
              <span class="font-mono text-gray-800">{{ toAccount() }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-500 font-medium">Status</span>
              <span class="text-green-600 font-semibold">Completed</span>
            </div>
          </div>

          <!-- Action buttons -->
          <div class="flex flex-col gap-3">
            <button (click)="close.emit()"
              class="w-full py-3 px-4 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
              Done
            </button>
            <button (click)="newTransfer.emit()"
              class="w-full py-3 px-4 rounded-xl border border-gray-200 hover:bg-gray-50 text-gray-700 text-sm font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-gray-300 focus:ring-offset-2">
              Make Another Transfer
            </button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    @keyframes modal-in {
      from { opacity: 0; transform: scale(0.95) translateY(8px); }
      to   { opacity: 1; transform: scale(1)    translateY(0); }
    }
    .animate-in {
      animation: modal-in 0.2s ease-out forwards;
    }
  `]
})
export class SuccessModal {
  visible = input.required<boolean>();
  transactionId = input<number | null>(null);
  amount = input<number>(0);
  toAccount = input<string>('');

  close = output<void>();
  newTransfer = output<void>();
}
