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
        return new AccountDto
        {
            Id = acc.Id,
            AccountNumber = acc.AccountNumber,
            Balance = acc.Balance,
            Status = acc.Status
        };
    }

    public async Task<IEnumerable<AccountDto>> GetByUserIdAsync(int userId)
    {
        var accounts = await _accounts.GetByUserIdAsync(userId);
        return accounts.Select(a => new AccountDto
        {
            Id = a.Id,
            AccountNumber = a.AccountNumber,
            Balance = a.Balance,
            Status = a.Status
        });
    }

    public async Task<AccountDto> CreateAsync(AccountCreateDto dto)
    {
        var user = await _users.GetByIdAsync(dto.UserId) ?? throw new InvalidOperationException("User not found");
        var account = new Account
        {
            AccountNumber = dto.AccountNumber,
            Balance = dto.InitialBalance,
            UserId = user.Id,
            Status = "Active"
        };
        await _accounts.AddAsync(account);
        await _accounts.SaveChangesAsync();

        return new AccountDto
        {
            Id = account.Id,
            AccountNumber = account.AccountNumber,
            Balance = account.Balance,
            Status = account.Status
        };
    }
}
