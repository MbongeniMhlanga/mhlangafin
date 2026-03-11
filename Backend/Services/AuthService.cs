using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Backend.DTOs.Auth;
using Backend.Repositories;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace Backend.Services;

public class AuthService : IAuthService
{
    private readonly IUserRepository _users;
    private readonly IAccountRepository _accounts;
    private readonly IConfiguration _config;

    public AuthService(IUserRepository users, IAccountRepository accounts, IConfiguration _config)
    {
        _users = users;
        _accounts = accounts;
        this._config = _config;
    }

    public async Task<LoginResponse?> AuthenticateAsync(LoginRequest request)
    {
        var user = await _users.GetByEmailAsync(request.Email);
        if (user is null) return null;

        // Use BCrypt to verify the password against the stored hash
        if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash)) return null;

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
            ExpiresAt = tokenDescriptor.Expires!.Value
        };
    }

    public async Task<bool> RegisterAsync(RegisterRequest request)
    {
        var existingUser = await _users.GetByEmailAsync(request.Email);
        if (existingUser is not null) return false;

        var user = new Backend.Models.Entities.User
        {
            FirstName = request.FirstName,
            LastName = request.LastName,
            Email = request.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = "User"
        };

        await _users.AddAsync(user);
        await _users.SaveChangesAsync();

        // Automatically create the Main Account for the new user with R1,000,000 balance
        var expiryDate = DateTime.UtcNow.AddYears(5).ToString("MM/yy");
        var cvv = Random.Shared.Next(100, 999).ToString();

        var mainAccount = new Backend.Models.Entities.Account
        {
            AccountName = "Main Account",
            AccountNumber = $"MFN{DateTime.UtcNow:yyyyMM}{Random.Shared.Next(10000, 99999)}",
            Balance = 1000000m,
            UserId = user.Id,
            IsMain = true,
            Status = "Active",
            ExpiryDate = expiryDate,
            CVV = cvv
        };
        await _accounts.AddAsync(mainAccount);
        await _accounts.SaveChangesAsync();

        return true;
    }
}
