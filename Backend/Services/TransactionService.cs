using Backend.DTOs.Transactions;
using Backend.Models.Entities;
using Backend.Repositories;
using Backend.Data;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class TransactionService : ITransactionService
{
    private readonly IAccountRepository _accounts;
    private readonly ITransactionRepository _txRepo;
    private readonly AppDbContext _db;

    public TransactionService(IAccountRepository accounts, ITransactionRepository txRepo, AppDbContext db)
    {
        _accounts = accounts;
        _txRepo = txRepo;
        _db = db;
    }

    public async Task<TransferResponse> TransferAsync(TransferRequest request)
    {
        if (request.Amount <= 0)
            return new TransferResponse { Status = "Failed", Message = "Invalid amount" };

        if (request.FromAccountNumber == request.ToAccountNumber)
            return new TransferResponse { Status = "Failed", Message = "Cannot transfer to the same account" };

        // Use a DB transaction to ensure atomicity
        await using var tx = await _db.Database.BeginTransactionAsync();
        try
        {
            var from = await _db.Accounts.FirstOrDefaultAsync(a => a.AccountNumber == request.FromAccountNumber);
            var to = await _db.Accounts.FirstOrDefaultAsync(a => a.AccountNumber == request.ToAccountNumber);

            if (from is null)
                return new TransferResponse { Status = "Failed", Message = $"Source account '{request.FromAccountNumber}' not found" };

            if (to is null)
                return new TransferResponse { Status = "Failed", Message = $"Destination account '{request.ToAccountNumber}' not found" };

            if (from.Balance < request.Amount)
                return new TransferResponse { Status = "Failed", Message = "Insufficient funds" };

            from.Balance -= request.Amount;
            to.Balance += request.Amount;

            var txEntity = new Transaction
            {
                FromAccountId = from.Id,
                ToAccountId = to.Id,
                Amount = request.Amount,
                Type = "Transfer",
                Timestamp = DateTime.UtcNow
            };

            await _txRepo.AddAsync(txEntity);
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

    public async Task<TransactionHistoryResponse> GetTransactionHistoryAsync(TransactionHistoryRequest request)
    {
        var account = await _db.Accounts.FirstOrDefaultAsync(a => a.AccountNumber == request.AccountNumber);
        if (account == null)
            return new TransactionHistoryResponse { Transactions = new List<TransactionDto>() };

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
                Description = $"{t.Type} - {t.Amount:C}",
                Timestamp = t.Timestamp
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

    public async Task<StatementResponse> GenerateStatementAsync(StatementRequest request, string format = "PDF")
    {
        var account = await _db.Accounts
            .Include(a => a.User)
            .FirstOrDefaultAsync(a => a.AccountNumber == request.AccountNumber);
        
        if (account == null)
            return new StatementResponse();

        // Get opening balance (balance at start date)
        var openingBalance = await CalculateBalanceAtDate(account.Id, request.StartDate);
        
        // Get transactions within date range
        var transactions = await _db.Transactions
            .Where(t => (t.FromAccountId == account.Id || t.ToAccountId == account.Id) &&
                       t.Timestamp >= request.StartDate && t.Timestamp <= request.EndDate)
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
                Description = $"{t.Type} - {t.Amount:C}",
                Timestamp = t.Timestamp
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
            AccountHolderName = account.User.FullName,
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
                       t.Timestamp < date)
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
}
