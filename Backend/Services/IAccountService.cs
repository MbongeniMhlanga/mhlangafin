using Backend.DTOs.Accounts;

namespace Backend.Services;

public interface IAccountService
{
    Task<AccountDto?> GetByIdAsync(int id);
    Task<AccountDto> CreateAsync(AccountCreateDto dto);
}
