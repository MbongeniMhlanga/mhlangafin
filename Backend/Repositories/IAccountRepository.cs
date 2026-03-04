using Backend.Models.Entities;

namespace Backend.Repositories;

public interface IAccountRepository
{
    Task<Account?> GetByIdAsync(int id);
    Task AddAsync(Account account);
    Task SaveChangesAsync();
}
