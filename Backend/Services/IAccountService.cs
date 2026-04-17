using Backend.DTOs.Accounts;

namespace Backend.Services;

public interface IAccountService
{
    Task<AccountDto?> GetByIdAsync(int id, int requesterUserId, bool isAdmin);
    Task<IEnumerable<AccountDto>> GetByUserIdAsync(int userId);
    Task<AccountDto> CreateAsync(AccountCreateDto dto, int requesterUserId, bool isAdmin);
}
