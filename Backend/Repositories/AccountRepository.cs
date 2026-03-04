using Backend.Data;
using Backend.Models.Entities;
using Microsoft.EntityFrameworkCore;

namespace Backend.Repositories;

public class AccountRepository : IAccountRepository
{
    private readonly AppDbContext _db;
    public AccountRepository(AppDbContext db) => _db = db;

    public async Task<Account?> GetByIdAsync(int id) =>
        await _db.Accounts.Include(a => a.User).FirstOrDefaultAsync(a => a.Id == id);

    public async Task<IEnumerable<Account>> GetByUserIdAsync(int userId) =>
        await _db.Accounts.Where(a => a.UserId == userId).ToListAsync();

    public async Task AddAsync(Account account) => await _db.Accounts.AddAsync(account);

    public async Task SaveChangesAsync() => await _db.SaveChangesAsync();
}
