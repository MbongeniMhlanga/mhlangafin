using System.Text;
using Backend.Data;
using Backend.DTOs.Accounts;
using Backend.DTOs.Admin;
using Backend.Models.Constants;
using Backend.Models.Entities;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class AdminService : IAdminService
{
    private readonly AppDbContext _db;

    public AdminService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<AdminUserDto>> GetUsersAsync()
    {
        var users = await _db.Users
            .Include(u => u.Accounts)
            .OrderBy(u => u.FirstName)
            .ThenBy(u => u.LastName)
            .ToListAsync();

        return users.Select(MapUserDto).ToList();
    }

    public async Task<AdminUserDto?> UpdateUserStatusAsync(int userId, string status, int adminUserId)
    {
        var user = await _db.Users
            .Include(u => u.Accounts)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user is null)
            return null;

        var normalizedStatus = NormalizeUserStatus(status);

        if (string.Equals(user.Role, UserRoles.Admin, StringComparison.OrdinalIgnoreCase) &&
            string.Equals(normalizedStatus, UserStatuses.Blocked, StringComparison.OrdinalIgnoreCase))
        {
            var activeAdminCount = await _db.Users.CountAsync(u =>
                string.Equals(u.Role, UserRoles.Admin, StringComparison.OrdinalIgnoreCase) &&
                string.Equals(u.Status, UserStatuses.Active, StringComparison.OrdinalIgnoreCase));

            if (activeAdminCount <= 1)
                throw new InvalidOperationException("You cannot block the last active admin.");
        }

        user.Status = normalizedStatus;
        await WriteAuditLogAsync(adminUserId, "UserStatusUpdated", $"User {user.Id} status changed to {normalizedStatus}.");
        await _db.SaveChangesAsync();

        return MapUserDto(user);
    }

    public async Task<AccountDto?> UpdateAccountStatusAsync(int accountId, string status, int adminUserId)
    {
        var account = await _db.Accounts.FirstOrDefaultAsync(a => a.Id == accountId);
        if (account is null)
            return null;

        var normalizedStatus = NormalizeAccountStatus(status);
        account.Status = normalizedStatus;

        await WriteAuditLogAsync(adminUserId, "AccountStatusUpdated", $"Account {account.Id} status changed to {normalizedStatus}.");
        await _db.SaveChangesAsync();

        return MapAccountDto(account);
    }

    public async Task<IReadOnlyList<AdminTransactionDto>> GetTransactionsAsync(string? status = null)
    {
        var query = _db.Transactions
            .Include(t => t.FromAccount)
            .Include(t => t.ToAccount)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status))
        {
            var normalizedStatus = NormalizeTransactionStatus(status);
            query = query.Where(t => t.Status == normalizedStatus);
        }

        var transactions = await query
            .OrderByDescending(t => t.Timestamp)
            .ToListAsync();

        return transactions.Select(MapTransactionDto).ToList();
    }

    public async Task<AdminTransactionDto> ApproveTransactionAsync(int transactionId, string? note, int adminUserId)
    {
        var transaction = await _db.Transactions
            .Include(t => t.FromAccount)
                .ThenInclude(a => a!.User)
            .Include(t => t.ToAccount)
                .ThenInclude(a => a!.User)
            .FirstOrDefaultAsync(t => t.Id == transactionId);

        if (transaction is null)
            throw new KeyNotFoundException("Transaction not found.");

        if (!transaction.RequiresApproval || !string.Equals(transaction.Status, TransactionStatuses.PendingApproval, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Only pending approval transactions can be approved.");

        if (transaction.FromAccount is null || transaction.ToAccount is null)
            throw new InvalidOperationException("Transaction accounts could not be loaded.");

        if (!IsOperational(transaction.FromAccount, transaction.FromAccount.User) ||
            !IsOperational(transaction.ToAccount, transaction.ToAccount.User))
            throw new InvalidOperationException("Frozen or blocked accounts cannot process transactions.");

        if (transaction.FromAccount.Balance < transaction.Amount)
            throw new InvalidOperationException("Insufficient funds to approve this transaction.");

        await using var dbTransaction = await _db.Database.BeginTransactionAsync();
        try
        {
            transaction.FromAccount.Balance -= transaction.Amount;
            transaction.ToAccount.Balance += transaction.Amount;
            transaction.Status = TransactionStatuses.Completed;
            transaction.ReviewedByAdminId = adminUserId;
            transaction.ReviewedAt = DateTime.UtcNow;
            transaction.ReviewNote = note;

            await WriteAuditLogAsync(adminUserId, "TransactionApproved", $"Transaction {transaction.Id} approved.");
            await _db.SaveChangesAsync();
            await dbTransaction.CommitAsync();
        }
        catch
        {
            await dbTransaction.RollbackAsync();
            throw;
        }

        return MapTransactionDto(transaction);
    }

    public async Task<AdminTransactionDto> RejectTransactionAsync(int transactionId, string? note, int adminUserId)
    {
        var transaction = await _db.Transactions
            .Include(t => t.FromAccount)
            .Include(t => t.ToAccount)
            .FirstOrDefaultAsync(t => t.Id == transactionId);

        if (transaction is null)
            throw new KeyNotFoundException("Transaction not found.");

        if (!transaction.RequiresApproval || !string.Equals(transaction.Status, TransactionStatuses.PendingApproval, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Only pending approval transactions can be rejected.");

        transaction.Status = TransactionStatuses.Rejected;
        transaction.ReviewedByAdminId = adminUserId;
        transaction.ReviewedAt = DateTime.UtcNow;
        transaction.ReviewNote = note;

        await WriteAuditLogAsync(adminUserId, "TransactionRejected", $"Transaction {transaction.Id} rejected.");
        await _db.SaveChangesAsync();

        return MapTransactionDto(transaction);
    }

    public async Task<ResetPasswordResponse> ResetUserPasswordAsync(int userId, ResetPasswordRequest request, int adminUserId)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user is null)
            throw new KeyNotFoundException("User not found.");

        var temporaryPassword = string.IsNullOrWhiteSpace(request.NewPassword)
            ? GenerateTemporaryPassword()
            : request.NewPassword.Trim();

        if (temporaryPassword.Length < 8)
            throw new InvalidOperationException("The new password must be at least 8 characters long.");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(temporaryPassword);
        await WriteAuditLogAsync(adminUserId, "PasswordReset", $"Password reset for user {user.Id}.");
        await _db.SaveChangesAsync();

        return new ResetPasswordResponse
        {
            UserId = user.Id,
            TemporaryPassword = temporaryPassword
        };
    }

    public async Task<AdminStatsDto> GetStatsAsync()
    {
        return new AdminStatsDto
        {
            TotalUsers = await _db.Users.CountAsync(),
            TotalCustomers = await _db.Users.CountAsync(u =>
                u.Role.ToLower() == UserRoles.Customer.ToLower() ||
                u.Role.ToLower() == UserRoles.LegacyCustomer.ToLower()),
            TotalAdmins = await _db.Users.CountAsync(u => u.Role.ToLower() == UserRoles.Admin.ToLower()),
            ActiveUsers = await _db.Users.CountAsync(u => u.Status.ToLower() == UserStatuses.Active.ToLower()),
            BlockedUsers = await _db.Users.CountAsync(u => u.Status.ToLower() == UserStatuses.Blocked.ToLower()),
            TotalAccounts = await _db.Accounts.CountAsync(),
            FrozenAccounts = await _db.Accounts.CountAsync(a => a.Status.ToLower() == AccountStatuses.Frozen.ToLower()),
            PendingTransactions = await _db.Transactions.CountAsync(t => t.Status.ToLower() == TransactionStatuses.PendingApproval.ToLower()),
            CompletedTransactions = await _db.Transactions.CountAsync(t => t.Status.ToLower() == TransactionStatuses.Completed.ToLower()),
            RejectedTransactions = await _db.Transactions.CountAsync(t => t.Status.ToLower() == TransactionStatuses.Rejected.ToLower()),
            TotalCompletedTransactionVolume = await _db.Transactions
                .Where(t => t.Status == TransactionStatuses.Completed)
                .SumAsync(t => (decimal?)t.Amount) ?? 0m
        };
    }

    private async Task WriteAuditLogAsync(int? userId, string action, string details)
    {
        await _db.AuditLogs.AddAsync(new AuditLog
        {
            UserId = userId,
            Action = action,
            Details = details,
            Timestamp = DateTime.UtcNow
        });
    }

    private static AdminUserDto MapUserDto(User user)
    {
        return new AdminUserDto
        {
            Id = user.Id,
            FirstName = user.FirstName,
            LastName = user.LastName,
            FullName = user.FullName,
            Email = user.Email,
            Role = user.Role,
            Status = user.Status,
            Accounts = user.Accounts?.Select(MapAccountDto).ToList() ?? new List<AccountDto>()
        };
    }

    private static AccountDto MapAccountDto(Account account)
    {
        return new AccountDto
        {
            Id = account.Id,
            AccountName = account.AccountName,
            AccountNumber = account.IsMain ? account.AccountNumber : "Savings Pocket",
            Balance = account.Balance,
            IsMain = account.IsMain,
            Status = account.Status,
            ExpiryDate = account.ExpiryDate,
            CVV = account.CVV
        };
    }

    private static AdminTransactionDto MapTransactionDto(Transaction transaction)
    {
        return new AdminTransactionDto
        {
            Id = transaction.Id,
            Type = transaction.Type,
            Amount = transaction.Amount,
            Status = transaction.Status,
            RequiresApproval = transaction.RequiresApproval,
            FromAccountNumber = transaction.FromAccount?.AccountNumber,
            ToAccountNumber = transaction.ToAccount?.AccountNumber,
            FromUserId = transaction.FromAccount?.UserId,
            ToUserId = transaction.ToAccount?.UserId,
            BeneficiaryReference = transaction.BeneficiaryReference,
            SenderReference = transaction.SenderReference,
            Timestamp = transaction.Timestamp,
            ReviewedByAdminId = transaction.ReviewedByAdminId,
            ReviewedAt = transaction.ReviewedAt,
            ReviewNote = transaction.ReviewNote
        };
    }

    private static string NormalizeUserStatus(string status)
    {
        if (string.Equals(status, UserStatuses.Active, StringComparison.OrdinalIgnoreCase))
            return UserStatuses.Active;

        if (string.Equals(status, UserStatuses.Blocked, StringComparison.OrdinalIgnoreCase) ||
            string.Equals(status, "Deactivated", StringComparison.OrdinalIgnoreCase))
            return UserStatuses.Blocked;

        throw new InvalidOperationException("Invalid user status.");
    }

    private static string NormalizeAccountStatus(string status)
    {
        if (string.Equals(status, AccountStatuses.Active, StringComparison.OrdinalIgnoreCase) ||
            string.Equals(status, "Unfrozen", StringComparison.OrdinalIgnoreCase))
            return AccountStatuses.Active;

        if (string.Equals(status, AccountStatuses.Frozen, StringComparison.OrdinalIgnoreCase))
            return AccountStatuses.Frozen;

        throw new InvalidOperationException("Invalid account status.");
    }

    private static string NormalizeTransactionStatus(string status)
    {
        if (string.Equals(status, TransactionStatuses.PendingApproval, StringComparison.OrdinalIgnoreCase))
            return TransactionStatuses.PendingApproval;

        if (string.Equals(status, TransactionStatuses.Completed, StringComparison.OrdinalIgnoreCase))
            return TransactionStatuses.Completed;

        if (string.Equals(status, TransactionStatuses.Rejected, StringComparison.OrdinalIgnoreCase))
            return TransactionStatuses.Rejected;

        throw new InvalidOperationException("Invalid transaction status.");
    }

    private static bool IsOperational(Account account, User? user)
    {
        return string.Equals(account.Status, AccountStatuses.Active, StringComparison.OrdinalIgnoreCase) &&
               user is not null &&
               string.Equals(user.Status, UserStatuses.Active, StringComparison.OrdinalIgnoreCase);
    }

    private static string GenerateTemporaryPassword()
    {
        const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%";
        var buffer = new StringBuilder(12);
        for (var i = 0; i < 12; i++)
            buffer.Append(chars[Random.Shared.Next(chars.Length)]);

        return buffer.ToString();
    }
}
