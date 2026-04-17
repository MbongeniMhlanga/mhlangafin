using Backend.DTOs.Accounts;
using Backend.DTOs.Admin;

namespace Backend.Services;

public interface IAdminService
{
    Task<IReadOnlyList<AdminUserDto>> GetUsersAsync();
    Task<AdminUserDto?> UpdateUserStatusAsync(int userId, string status, int adminUserId);
    Task<AccountDto?> UpdateAccountStatusAsync(int accountId, string status, int adminUserId);
    Task<IReadOnlyList<AdminTransactionDto>> GetTransactionsAsync(string? status = null);
    Task<AdminTransactionDto> ApproveTransactionAsync(int transactionId, string? note, int adminUserId);
    Task<AdminTransactionDto> RejectTransactionAsync(int transactionId, string? note, int adminUserId);
    Task<ResetPasswordResponse> ResetUserPasswordAsync(int userId, ResetPasswordRequest request, int adminUserId);
    Task<AdminStatsDto> GetStatsAsync();
}
