using Backend.DTOs.Accounts;
using Backend.Models.Entities;
using Backend.Repositories;
using System.Linq;
using System.Collections.Generic;

namespace Backend.Services;

public class AccountService : IAccountService
{
    private readonly IAccountRepository _accounts;
    private readonly IUserRepository _users;

    public AccountService(IAccountRepository accounts, IUserRepository users)
    {
        _accounts = accounts;
        _users = users;
    }

    public async Task<AccountDto?> GetByIdAsync(int id)
    {
        var acc = await _accounts.GetByIdAsync(id);
        if (acc is null) return null;
        return MapToDto(acc);
    }

    public async Task<IEnumerable<AccountDto>> GetByUserIdAsync(int userId)
    {
        var accounts = await _accounts.GetByUserIdAsync(userId);
        return accounts.Select(MapToDto);
    }

    public async Task<AccountDto> CreateAsync(AccountCreateDto dto)
    {
        var user = await _users.GetByIdAsync(dto.UserId) ?? throw new InvalidOperationException("User not found");
        var existingAccounts = await _accounts.GetByUserIdAsync(dto.UserId);
        bool isFirst = !existingAccounts.Any();

        // One account number per user (Main Account only)
        string accountNumber;
        if (isFirst) {
            accountNumber = $"MFN{DateTime.UtcNow:yyyyMM}{Random.Shared.Next(10000, 99999)}";
        } else {
            // Sub-accounts don't show an account number to the user, but we'll store a link
            var mainAcc = existingAccounts.FirstOrDefault(a => a.IsMain);
            accountNumber = mainAcc?.AccountNumber ?? "PENDING";
        }

        var account = new Account
        {
            AccountName = dto.AccountName,
            AccountNumber = accountNumber,
            Balance = dto.InitialBalance,
            UserId = user.Id,
            IsMain = isFirst,
            Status = "Active"
        };
        await _accounts.AddAsync(account);
        await _accounts.SaveChangesAsync();

        return MapToDto(account);
    }

    private static AccountDto MapToDto(Account a) => new AccountDto
    {
        Id = a.Id,
        AccountName = a.AccountName,
        AccountNumber = a.IsMain ? a.AccountNumber : "Savings Pocket",
        Balance = a.Balance,
        IsMain = a.IsMain,
        Status = a.Status
    };
}
