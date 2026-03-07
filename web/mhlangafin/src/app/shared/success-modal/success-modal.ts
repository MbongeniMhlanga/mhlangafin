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
        <div class="relative bg-white/95 backdrop-blur-lg rounded-2xl shadow-2xl max-w-md w-full p-8 text-center animate-in border border-white/20">

          <!-- Success check circle -->
          <div class="mx-auto mb-6 flex items-center justify-center w-16 h-16 bg-gradient-to-r from-emerald-500 to-teal-500 rounded-full shadow-lg">
            <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"/>
            </svg>
          </div>

          <h2 id="modal-title" class="text-2xl font-bold text-gray-900 mb-2">Transfer Successful! 🎉</h2>
          <p class="text-gray-600 text-sm mb-6">Your funds have been securely transferred.</p>

          <!-- Transaction detail -->
          <div class="bg-gradient-to-r from-emerald-50 to-teal-50 border border-emerald-200 rounded-xl px-6 py-4 mb-6 text-left space-y-3">
            <div class="flex justify-between items-center py-2 border-b border-emerald-100">
              <span class="text-sm text-gray-600 font-medium">Transaction ID</span>
              <span class="text-sm font-mono font-semibold text-gray-900">#{{ transactionId() }}</span>
            </div>
            <div class="flex justify-between items-center py-2 border-b border-emerald-100">
              <span class="text-sm text-gray-600 font-medium">Amount</span>
              <span class="text-lg font-bold text-gray-900">R{{ amount() | number:'1.2-2' }}</span>
            </div>
            <div class="flex justify-between items-center py-2 border-b border-emerald-100">
              <span class="text-sm text-gray-600 font-medium">To Account</span>
              <span class="text-sm font-mono text-gray-800">{{ toAccount() }}</span>
            </div>
            <div class="flex justify-between items-center py-2">
              <span class="text-sm text-gray-600 font-medium">Status</span>
              <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                <span class="w-2 h-2 bg-green-500 rounded-full mr-2"></span>
                Completed
              </span>
            </div>
          </div>

          <!-- Action buttons -->
          <div class="flex flex-col gap-3">
            <button (click)="close.emit()"
              class="w-full py-3 px-4 bg-gradient-to-r from-gray-600 to-gray-700 text-white text-sm font-semibold rounded-lg shadow-md hover:shadow-lg transform hover:-translate-y-0.5 transition-all duration-200">
              Back to Dashboard
            </button>
            <button (click)="newTransfer.emit()"
              class="w-full py-3 px-4 bg-gradient-to-r from-emerald-600 to-teal-600 text-white text-sm font-semibold rounded-lg shadow-md hover:shadow-lg transform hover:-translate-y-0.5 transition-all duration-200">
              Make Another Transfer
            </button>
          </div>

          <!-- Security note -->
          <div class="mt-6 flex items-center justify-center space-x-2 text-xs text-gray-500">
            <svg class="w-4 h-4 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path>
            </svg>
            <span>Transaction secured with bank-level encryption</span>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    @keyframes modal-in {
      from { opacity: 0; transform: scale(0.95) translateY(12px); }
      to   { opacity: 1; transform: scale(1)    translateY(0); }
    }
    .animate-in {
      animation: modal-in 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards;
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
