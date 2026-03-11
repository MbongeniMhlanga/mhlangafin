using Backend.DTOs.Beneficiaries;
using Backend.Models.Entities;
using Backend.Repositories;

namespace Backend.Services;

public class BeneficiaryService : IBeneficiaryService
{
    private readonly IBeneficiaryRepository _beneficiaries;

    public BeneficiaryService(IBeneficiaryRepository beneficiaries)
    {
        _beneficiaries = beneficiaries;
    }

    public async Task<IEnumerable<BeneficiaryDto>> GetByUserIdAsync(int userId)
    {
        var beneficiaries = await _beneficiaries.GetByUserIdAsync(userId);
        return beneficiaries.Select(b => new BeneficiaryDto
        {
            Id = b.Id,
            Name = b.Name,
            AccountNumber = b.AccountNumber,
            BankName = b.BankName
        });
    }

    public async Task<BeneficiaryDto> AddAsync(BeneficiaryCreateDto dto)
    {
        var beneficiary = new Beneficiary
        {
            Name = dto.Name,
            AccountNumber = dto.AccountNumber,
            BankName = dto.BankName,
            UserId = dto.UserId
        };

        await _beneficiaries.AddAsync(beneficiary);
        await _beneficiaries.SaveChangesAsync();

        return new BeneficiaryDto
        {
            Id = beneficiary.Id,
            Name = beneficiary.Name,
            AccountNumber = beneficiary.AccountNumber,
            BankName = beneficiary.BankName
        };
    }

    public async Task<bool> DeleteAsync(int id, int userId)
    {
        var beneficiary = await _beneficiaries.GetByIdAsync(id);
        if (beneficiary == null || beneficiary.UserId != userId) return false;

        await _beneficiaries.DeleteAsync(beneficiary);
        await _beneficiaries.SaveChangesAsync();
        return true;
    }
}
