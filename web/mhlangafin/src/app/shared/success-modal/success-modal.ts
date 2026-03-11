import { Component, input, output, ChangeDetectionStrategy } from '@angular/core';
import { CommonModule, DecimalPipe } from '@angular/common';

@Component({
  selector: 'app-success-modal',
  standalone: true,
  imports: [CommonModule, DecimalPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (visible()) {
      <div class="fixed inset-0 z-[200] flex items-center justify-center p-6 sm:p-8"
           role="dialog" aria-modal="true" aria-labelledby="modal-title">
        
        <!-- Backdrop -->
        <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-md transition-opacity duration-500" (click)="close.emit()"></div>

        <!-- Modal Card -->
        <div class="relative bg-white rounded-[3rem] shadow-[0_32px_64px_-16px_rgba(15,23,42,0.15)] max-w-md w-full overflow-hidden animate-slide-up border border-slate-100">
          
          <!-- Top Accent Bar -->
          <div class="h-2 w-full bg-gradient-to-r from-emerald-400 via-teal-500 to-emerald-400"></div>

          <div class="p-10 pt-12 text-center">
            <!-- Animated Success Icon -->
            <div class="mx-auto mb-8 relative">
              <div class="absolute inset-0 bg-emerald-100 rounded-full animate-pulse scale-150 opacity-20"></div>
              <div class="relative w-20 h-20 bg-emerald-500 text-white rounded-full flex items-center justify-center shadow-2xl shadow-emerald-500/40">
                <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"/>
                </svg>
              </div>
            </div>

            <h2 id="modal-title" class="text-3xl font-black text-slate-900 tracking-tight mb-3">Beneficiary Paid</h2>
            <p class="text-slate-500 font-medium mb-10 leading-relaxed">Your transaction has been authorized and processed instantly.</p>

            <!-- Transaction Details Card -->
            <div class="bg-slate-50 rounded-[2rem] p-8 mb-10 space-y-5 text-left border border-slate-100">
              <div class="flex justify-between items-center group">
                <span class="text-[10px] uppercase tracking-widest font-bold text-slate-400">Transaction ID</span>
                <span class="text-xs font-black text-slate-900 font-mono tracking-tighter">#{{ transactionId() || '6512-8921-X' }}</span>
              </div>
              
              <div class="flex justify-between items-end">
                <div>
                  <span class="text-[10px] uppercase tracking-widest font-bold text-slate-400 block mb-1">Amount Paid</span>
                  <span class="text-3xl font-black text-slate-900 tracking-tighter">R{{ amount() | number:'1.2-2' }}</span>
                </div>
                <div class="text-right">
                  <span class="text-[10px] uppercase tracking-widest font-bold text-slate-400 block mb-1">To Account</span>
                  <span class="text-xs font-bold text-slate-700 bg-white px-3 py-1.5 rounded-lg shadow-sm border border-slate-100">{{ toAccount() }}</span>
                </div>
              </div>

              <div class="pt-4 border-t border-slate-200/60 flex items-center justify-between">
                <span class="text-[10px] uppercase tracking-widest font-bold text-slate-400">Status</span>
                <div class="flex items-center gap-2">
                  <div class="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"></div>
                  <span class="text-[10px] font-black text-emerald-600 uppercase tracking-widest">Authorized</span>
                </div>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="space-y-4">
              <button (click)="newTransfer.emit()"
                class="w-full btn-primary py-5 text-lg shadow-xl shadow-blue-500/10">
                Pay Another Beneficiary
              </button>
              <button (click)="close.emit()"
                class="w-full btn-secondary py-5 text-lg hover:bg-slate-50 border-slate-200">
                Return to Dashboard
              </button>
            </div>

            <!-- Security Footer -->
            <div class="mt-10 flex items-center justify-center gap-3 py-4 bg-slate-50/50 rounded-2xl border border-slate-100/50">
              <svg class="w-5 h-5 text-slate-400" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M2.166 4.9L10 1.55l7.834 3.35a1 1 0 01.666.945V10c0 5.825-4.139 10.285-8.5 11.5-4.361-1.215-8.5-5.675-8.5-11.5V5.845a1 1 0 01.666-.945zM10 7a1 1 0 00-1 1v4a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd"/>
              </svg>
              <span class="text-[10px] font-bold text-slate-400 uppercase tracking-[0.2em]">End-to-End Encrypted</span>
            </div>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    @keyframes slide-up {
      from { opacity: 0; transform: translateY(30px) scale(0.98); }
      to { opacity: 1; transform: translateY(0) scale(1); }
    }
    .animate-slide-up {
      animation: slide-up 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards;
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
