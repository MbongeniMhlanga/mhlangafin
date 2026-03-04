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

        // Use a DB transaction to ensure atomicity
        await using var tx = await _db.Database.BeginTransactionAsync();
        try
        {
            var from = await _db.Accounts.FirstOrDefaultAsync(a => a.Id == request.FromAccountId);
            var to = await _db.Accounts.FirstOrDefaultAsync(a => a.Id == request.ToAccountId);

            if (from is null || to is null)
                return new TransferResponse { Status = "Failed", Message = "Account not found" };

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
}
