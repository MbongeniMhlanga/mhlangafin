using Backend.Data;
using Backend.Models.Entities;

namespace Backend.Repositories;

public class TransactionRepository : ITransactionRepository
{
    private readonly AppDbContext _db;
    public TransactionRepository(AppDbContext db) => _db = db;

    public async Task AddAsync(Transaction tx) => await _db.Transactions.AddAsync(tx);

    public async Task SaveChangesAsync() => await _db.SaveChangesAsync();
}
