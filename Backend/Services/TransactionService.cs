using Backend.DTOs.Transactions;
using Backend.Models.Entities;
using Backend.Repositories;
using Backend.Data;
using Backend.Models.Constants;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class TransactionService : ITransactionService
{
    private readonly IAccountRepository _accounts;
    private readonly ITransactionRepository _txRepo;
    private readonly AppDbContext _db;
    private readonly decimal _approvalThreshold;

    public TransactionService(IAccountRepository accounts, ITransactionRepository txRepo, AppDbContext db, IConfiguration configuration)
    {
        _accounts = accounts;
        _txRepo = txRepo;
        _db = db;
        _approvalThreshold = configuration.GetValue<decimal?>("Transactions:ApprovalThreshold") ?? 50000m;
    }

    public async Task<TransferResponse> TransferAsync(TransferRequest request, int requesterUserId, bool isAdmin)
    {
        if (request.Amount <= 0)
            return new TransferResponse { Status = "Failed", Message = "Invalid amount" };

        if (request.FromAccountNumber == request.ToAccountNumber)
            return new TransferResponse { Status = "Failed", Message = "Cannot transfer to the same account" };

        // Use a DB transaction to ensure atomicity
        await using var tx = await _db.Database.BeginTransactionAsync();
        try
        {
            var from = await _db.Accounts.Include(a => a.User).FirstOrDefaultAsync(a => a.AccountNumber == request.FromAccountNumber);
            var to = await _db.Accounts.Include(a => a.User).FirstOrDefaultAsync(a => a.AccountNumber == request.ToAccountNumber);

            if (from is null)
                return new TransferResponse { Status = "Failed", Message = $"Source account '{request.FromAccountNumber}' not found" };

            if (to is null)
                return new TransferResponse { Status = "Failed", Message = $"Destination account '{request.ToAccountNumber}' not found" };

            if (!isAdmin && from.UserId != requesterUserId)
                return new TransferResponse { Status = "Failed", Message = "Unauthorized transfer" };

            if (!IsOperational(from, from.User) || !IsOperational(to, to.User))
                return new TransferResponse { Status = "Failed", Message = "Frozen or blocked accounts cannot process transfers" };

            if (from.Balance < request.Amount)
                return new TransferResponse { Status = "Failed", Message = "Insufficient funds" };

            var txEntity = new Transaction
            {
                FromAccountId = from.Id,
                ToAccountId = to.Id,
                Amount = request.Amount,
                Type = "Transfer",
                Status = request.Amount >= _approvalThreshold ? TransactionStatuses.PendingApproval : TransactionStatuses.Completed,
                RequiresApproval = request.Amount >= _approvalThreshold,
                BeneficiaryReference = request.BeneficiaryReference,
                SenderReference = request.SenderReference,
                Timestamp = DateTime.UtcNow
            };

            if (txEntity.RequiresApproval)
            {
                await _txRepo.AddAsync(txEntity);
                await WriteAuditLogAsync(requesterUserId, "TransactionQueuedForApproval", $"Transaction from {from.AccountNumber} to {to.AccountNumber} queued for approval.");
                await _db.SaveChangesAsync();
                await tx.CommitAsync();

                return new TransferResponse
                {
                    TransactionId = txEntity.Id,
                    Status = TransactionStatuses.PendingApproval,
                    Message = "Transfer queued for admin approval"
                };
            }

            from.Balance -= request.Amount;
            to.Balance += request.Amount;
            await _txRepo.AddAsync(txEntity);
            await WriteAuditLogAsync(requesterUserId, "TransferCompleted", $"Transaction {txEntity.Type} completed between {from.AccountNumber} and {to.AccountNumber}.");
            await _db.SaveChangesAsync();

            await tx.CommitAsync();

            return new TransferResponse
            {
                TransactionId = txEntity.Id,
                Status = "Success",
                Message = "Transfer completed successfully"
            };
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    public async Task<TransferResponse> InternalTransferAsync(InternalTransferRequest request, int requesterUserId, bool isAdmin)
    {
        if (request.Amount <= 0)
            return new TransferResponse { Status = "Failed", Message = "Invalid amount" };

        if (request.FromAccountId == request.ToAccountId)
            return new TransferResponse { Status = "Failed", Message = "Cannot transfer to the same account" };

        await using var tx = await _db.Database.BeginTransactionAsync();
        try
        {
            var from = await _db.Accounts.Include(a => a.User).FirstOrDefaultAsync(a => a.Id == request.FromAccountId);
            var to = await _db.Accounts.Include(a => a.User).FirstOrDefaultAsync(a => a.Id == request.ToAccountId);

            if (from is null || to is null)
                return new TransferResponse { Status = "Failed", Message = "Account not found" };

            if (from.UserId != to.UserId)
                return new TransferResponse { Status = "Failed", Message = "Unauthorized transfer" };

            if (!isAdmin && from.UserId != requesterUserId)
                return new TransferResponse { Status = "Failed", Message = "Unauthorized transfer" };

            if (!IsOperational(from, from.User) || !IsOperational(to, to.User))
                return new TransferResponse { Status = "Failed", Message = "Frozen or blocked accounts cannot process transfers" };

            if (from.Balance < request.Amount)
                return new TransferResponse { Status = "Failed", Message = "Insufficient funds" };

            var txEntity = new Transaction
            {
                FromAccountId = from.Id,
                ToAccountId = to.Id,
                Amount = request.Amount,
                Type = "Internal Transfer",
                Status = request.Amount >= _approvalThreshold ? TransactionStatuses.PendingApproval : TransactionStatuses.Completed,
                RequiresApproval = request.Amount >= _approvalThreshold,
                SenderReference = $"To {to.AccountName}",
                BeneficiaryReference = $"From {from.AccountName}",
                Timestamp = DateTime.UtcNow
            };

            if (txEntity.RequiresApproval)
            {
                await _txRepo.AddAsync(txEntity);
                await WriteAuditLogAsync(requesterUserId, "InternalTransferQueuedForApproval", $"Internal transfer {txEntity.Id} queued for approval.");
                await _db.SaveChangesAsync();
                await tx.CommitAsync();

                return new TransferResponse
                {
                    TransactionId = txEntity.Id,
                    Status = TransactionStatuses.PendingApproval,
                    Message = "Funds move queued for admin approval"
                };
            }

            from.Balance -= request.Amount;
            to.Balance += request.Amount;
            await _txRepo.AddAsync(txEntity);
            await WriteAuditLogAsync(requesterUserId, "InternalTransferCompleted", $"Internal transfer between accounts {from.Id} and {to.Id} completed.");
            await _db.SaveChangesAsync();
            await tx.CommitAsync();

            return new TransferResponse
            {
                TransactionId = txEntity.Id,
                Status = "Success",
                Message = "Funds moved successfully"
            };
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    public async Task<TransactionHistoryResponse> GetTransactionHistoryAsync(TransactionHistoryRequest request, int requesterUserId, bool isAdmin)
    {
        Account? account = null;
        if (int.TryParse(request.AccountNumber, out int accId))
            account = await _db.Accounts.FindAsync(accId);

        if (account == null)
            account = await _db.Accounts.FirstOrDefaultAsync(a => a.AccountNumber == request.AccountNumber);

        if (account == null)
            return new TransactionHistoryResponse { Transactions = new List<TransactionDto>() };

        if (!isAdmin && account.UserId != requesterUserId)
            throw new UnauthorizedAccessException("You are not allowed to view these transactions.");

        var query = _db.Transactions
            .Where(t => t.FromAccountId == account.Id || t.ToAccountId == account.Id)
            .OrderByDescending(t => t.Timestamp);

        if (request.StartDate.HasValue)
            query = query.Where(t => t.Timestamp >= request.StartDate.Value).OrderByDescending(t => t.Timestamp);
        
        if (request.EndDate.HasValue)
            query = query.Where(t => t.Timestamp <= request.EndDate.Value).OrderByDescending(t => t.Timestamp);

        var totalTransactions = await query.CountAsync();
        var totalPages = (int)Math.Ceiling((double)totalTransactions / request.PageSize);

        var transactions = await query
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Include(t => t.FromAccount)
            .Include(t => t.ToAccount)
            .Select(t => new TransactionDto
            {
                Id = t.Id,
                Type = t.Type,
                Amount = t.Amount,
                FromAccountNumber = t.FromAccount!.AccountNumber,
                ToAccountNumber = t.ToAccount!.AccountNumber,
                Description = t.FromAccountId == account.Id 
                    ? (t.SenderReference ?? $"{t.Type} - {t.Amount:C}") 
                    : (t.BeneficiaryReference ?? $"{t.Type} - {t.Amount:C}"),
                BeneficiaryReference = t.BeneficiaryReference,
                SenderReference = t.SenderReference,
                Timestamp = t.Timestamp,
                Status = t.Status,
                RequiresApproval = t.RequiresApproval
            })
            .ToListAsync();

        return new TransactionHistoryResponse
        {
            TotalTransactions = totalTransactions,
            Page = request.Page,
            PageSize = request.PageSize,
            TotalPages = totalPages,
            Transactions = transactions
        };
    }

    public async Task<StatementResponse> GenerateStatementAsync(StatementRequest request, int requesterUserId, bool isAdmin, string format = "PDF")
    {
        Account? account = null;
        if (int.TryParse(request.AccountNumber, out int accId))
            account = await _db.Accounts.Include(a => a.User).FirstOrDefaultAsync(a => a.Id == accId);

        if (account == null)
            account = await _db.Accounts.Include(a => a.User).FirstOrDefaultAsync(a => a.AccountNumber == request.AccountNumber);
        
        if (account == null)
            return new StatementResponse();

        if (!isAdmin && account.UserId != requesterUserId)
            throw new UnauthorizedAccessException("You are not allowed to generate a statement for this account.");

        // Get opening balance (balance at start date)
        var openingBalance = await CalculateBalanceAtDate(account.Id, request.StartDate);
        
        // Get transactions within date range
        var transactions = await _db.Transactions
            .Where(t => (t.FromAccountId == account.Id || t.ToAccountId == account.Id) &&
                       t.Timestamp >= request.StartDate &&
                       t.Timestamp <= request.EndDate &&
                       t.Status == TransactionStatuses.Completed)
            .Include(t => t.FromAccount)
            .Include(t => t.ToAccount)
            .OrderBy(t => t.Timestamp)
            .Select(t => new TransactionDto
            {
                Id = t.Id,
                Type = t.Type,
                Amount = t.Amount,
                FromAccountNumber = t.FromAccount!.AccountNumber,
                ToAccountNumber = t.ToAccount!.AccountNumber,
                Description = t.FromAccountId == account.Id 
                    ? (t.SenderReference ?? $"{t.Type} - {t.Amount:C}") 
                    : (t.BeneficiaryReference ?? $"{t.Type} - {t.Amount:C}"),
                BeneficiaryReference = t.BeneficiaryReference,
                SenderReference = t.SenderReference,
                Timestamp = t.Timestamp,
                Status = t.Status,
                RequiresApproval = t.RequiresApproval
            })
            .ToListAsync();

        // Calculate closing balance
        var closingBalance = openingBalance;
        foreach (var tx in transactions)
        {
            if (tx.FromAccountNumber == account.AccountNumber)
                closingBalance -= tx.Amount;
            else if (tx.ToAccountNumber == account.AccountNumber)
                closingBalance += tx.Amount;
        }

        return new StatementResponse
        {
            AccountNumber = account.AccountNumber,
            AccountHolderName = account.User?.FullName ?? "Unknown",
            StartDate = request.StartDate,
            EndDate = request.EndDate,
            OpeningBalance = openingBalance,
            ClosingBalance = closingBalance,
            Transactions = transactions,
            Format = format
        };
    }

    private async Task<decimal> CalculateBalanceAtDate(int accountId, DateTime date)
    {
        // Get initial balance (account creation balance)
        var account = await _db.Accounts.FindAsync(accountId);
        if (account == null) return 0;

        var initialBalance = account.Balance;

        // Get all transactions before the specified date
        var transactions = await _db.Transactions
            .Where(t => (t.FromAccountId == accountId || t.ToAccountId == accountId) &&
                       t.Timestamp < date &&
                       t.Status == TransactionStatuses.Completed)
            .ToListAsync();

        // Calculate balance at that date
        var balance = initialBalance;
        foreach (var tx in transactions)
        {
            if (tx.FromAccountId == accountId)
                balance -= tx.Amount;
            else if (tx.ToAccountId == accountId)
                balance += tx.Amount;
        }

        return balance;
    }

    private async Task WriteAuditLogAsync(int? userId, string action, string details)
    {
        await _db.AuditLogs.AddAsync(new AuditLog
        {
            UserId = userId,
            Action = action,
            Details = details,
            Timestamp = DateTime.UtcNow
        });
    }

    private static bool IsOperational(Account account, User? user)
    {
        return string.Equals(account.Status, AccountStatuses.Active, StringComparison.OrdinalIgnoreCase) &&
               user is not null &&
               string.Equals(user.Status, UserStatuses.Active, StringComparison.OrdinalIgnoreCase);
    }
}
