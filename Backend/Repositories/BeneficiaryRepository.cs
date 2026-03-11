using Backend.Data;
using Backend.Models.Entities;
using Microsoft.EntityFrameworkCore;

namespace Backend.Repositories;

public class BeneficiaryRepository : IBeneficiaryRepository
{
    private readonly AppDbContext _context;

    public BeneficiaryRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Beneficiary?> GetByIdAsync(int id)
    {
        return await _context.Beneficiaries.FindAsync(id);
    }

    public async Task<IEnumerable<Beneficiary>> GetByUserIdAsync(int userId)
    {
        return await _context.Beneficiaries
            .Where(b => b.UserId == userId)
            .OrderBy(b => b.Name)
            .ToListAsync();
    }

    public async Task AddAsync(Beneficiary beneficiary)
    {
        await _context.Beneficiaries.AddAsync(beneficiary);
    }

    public async Task UpdateAsync(Beneficiary beneficiary)
    {
        _context.Beneficiaries.Update(beneficiary);
        await Task.CompletedTask;
    }

    public async Task DeleteAsync(Beneficiary beneficiary)
    {
        _context.Beneficiaries.Remove(beneficiary);
        await Task.CompletedTask;
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }
}
