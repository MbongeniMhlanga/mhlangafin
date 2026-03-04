using Backend.Models.Entities;

namespace Backend.Repositories;

public interface ITransactionRepository
{
    Task AddAsync(Transaction tx);
    Task SaveChangesAsync();
}
