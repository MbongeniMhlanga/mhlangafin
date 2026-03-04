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

        // Auto-generate a unique account number: MFN-YearMonth-RandomSuffix
        var accountNumber = $"MFN{DateTime.UtcNow:yyyyMM}{Random.Shared.Next(10000, 99999)}";

        var account = new Account
        {
            AccountName = dto.AccountName,
            AccountNumber = accountNumber,
            Balance = dto.InitialBalance,
            UserId = user.Id,
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
        AccountNumber = a.AccountNumber,
        Balance = a.Balance,
        Status = a.Status
    };
}
