using Backend.DTOs.Auth;

namespace Backend.Services;

public interface IAuthService
{
    Task<LoginResponse?> AuthenticateAsync(LoginRequest request);
    Task<bool> RegisterAsync(RegisterRequest request);
}
