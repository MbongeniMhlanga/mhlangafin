using Backend.DTOs.Beneficiaries;

namespace Backend.Services;

public interface IBeneficiaryService
{
    Task<IEnumerable<BeneficiaryDto>> GetByUserIdAsync(int userId);
    Task<BeneficiaryDto> AddAsync(BeneficiaryCreateDto dto);
    Task<bool> DeleteAsync(int id, int userId);
}
