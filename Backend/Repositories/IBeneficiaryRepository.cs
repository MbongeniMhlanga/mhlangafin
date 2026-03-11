using Backend.Models.Entities;

namespace Backend.Repositories;

public interface IBeneficiaryRepository
{
    Task<Beneficiary?> GetByIdAsync(int id);
    Task<IEnumerable<Beneficiary>> GetByUserIdAsync(int userId);
    Task AddAsync(Beneficiary beneficiary);
    Task UpdateAsync(Beneficiary beneficiary);
    Task DeleteAsync(Beneficiary beneficiary);
    Task SaveChangesAsync();
}
