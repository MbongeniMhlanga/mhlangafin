using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Backend.Data;
using Backend.DTOs.Auth;
using Backend.Models.Constants;
using Backend.Models.Entities;
using Backend.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace Backend.Services;

public class AuthService : IAuthService
{
    private readonly IUserRepository _users;
    private readonly IAccountRepository _accounts;
    private readonly IConfiguration _config;
    private readonly AppDbContext _db;

    public AuthService(IUserRepository users, IAccountRepository accounts, IConfiguration _config, AppDbContext db)
    {
        _users = users;
        _accounts = accounts;
        this._config = _config;
        _db = db;
    }

    public async Task<LoginResponse?> AuthenticateAsync(LoginRequest request)
    {
        var user = await _users.GetByEmailAsync(request.Email);
        if (user is null) return null;

        // Use BCrypt to verify the password against the stored hash
        if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash)) return null;
        if (!string.Equals(user.Status, UserStatuses.Active, StringComparison.OrdinalIgnoreCase)) return null;

        var key = Encoding.UTF8.GetBytes(_config["Jwt:Key"] ?? throw new InvalidOperationException("Jwt:Key missing"));
        var tokenHandler = new JwtSecurityTokenHandler();
        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.FullName),
                new Claim(ClaimTypes.GivenName, user.FirstName),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role)
            }),
            Expires = DateTime.UtcNow.AddMinutes(double.Parse(_config["Jwt:ExpiresMinutes"] ?? "60")),
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature),
            Issuer = _config["Jwt:Issuer"],
            Audience = _config["Jwt:Audience"]
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        return new LoginResponse
        {
            Token = tokenHandler.WriteToken(token),
            ExpiresAt = tokenDescriptor.Expires!.Value,
            UserId = user.Id,
            Role = user.Role,
            Status = user.Status
        };
    }

    public async Task<bool> RegisterAsync(RegisterRequest request)
    {
        var existingUser = await _users.GetByEmailAsync(request.Email);
        if (existingUser is not null) return false;

        var user = new User
        {
            FirstName = request.FirstName,
            LastName = request.LastName,
            Email = request.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = UserRoles.Customer,
            Status = UserStatuses.Active
        };

        await using var transaction = await _db.Database.BeginTransactionAsync();
        try
        {
            await _users.AddAsync(user);
            await _users.SaveChangesAsync();

            // Automatically create the Main Account for the new user with R1,000,000 balance
            var expiryDate = DateTime.UtcNow.AddYears(5).ToString("MM/yy");
            var cvv = Random.Shared.Next(100, 999).ToString();

            var mainAccount = new Account
            {
                AccountName = "Main Account",
                AccountNumber = $"MFN{DateTime.UtcNow:yyyyMM}{Random.Shared.Next(10000, 99999)}",
                Balance = 1000000m,
                UserId = user.Id,
                IsMain = true,
                Status = AccountStatuses.Active,
                ExpiryDate = expiryDate,
                CVV = cvv
            };
            await _accounts.AddAsync(mainAccount);
            await _accounts.SaveChangesAsync();

            await _db.AuditLogs.AddAsync(new AuditLog
            {
                UserId = user.Id,
                Action = "UserRegistered",
                Details = $"User {user.Email} registered successfully.",
                Timestamp = DateTime.UtcNow
            });
            await _db.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }

        return true;
    }

    public async Task<ProfileResponse?> GetProfileAsync(int userId)
    {
        var user = await _users.GetByIdAsync(userId);
        if (user is null) return null;

        return MapProfile(user);
    }

    public async Task<ProfileResponse?> UpdateProfileAsync(int userId, UpdateProfileRequest request)
    {
        var user = await _users.GetByIdAsync(userId);
        if (user is null) return null;

        var firstName = request.FirstName.Trim();
        var lastName = request.LastName.Trim();
        var email = request.Email.Trim();

        var emailInUse = await _users.GetByEmailAsync(email);
        if (emailInUse is not null && emailInUse.Id != userId) return null;

        user.FirstName = firstName;
        user.LastName = lastName;
        user.Email = email;

        await _users.SaveChangesAsync();

        return MapProfile(user);
    }

    public async Task<bool> ChangePasswordAsync(int userId, ChangePasswordRequest request)
    {
        var user = await _users.GetByIdAsync(userId);
        if (user is null) return false;

        if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
            return false;

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        await _users.SaveChangesAsync();

        return true;
    }

    private static ProfileResponse MapProfile(User user) => new()
    {
        UserId = user.Id,
        FirstName = user.FirstName,
        LastName = user.LastName,
        Email = user.Email,
        Role = user.Role
    };
}
