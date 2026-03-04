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
    private readonly IConfiguration _config;

    public AuthService(IUserRepository users, IConfiguration config)
    {
        _users = users;
        _config = config;
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
}
