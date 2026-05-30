using Backend.DTOs.Auth;

namespace Backend.Services;

public interface IAuthService
{
    Task<LoginResponse?> AuthenticateAsync(LoginRequest request);
    Task<bool> RegisterAsync(RegisterRequest request);
    Task<ProfileResponse?> GetProfileAsync(int userId);
    Task<ProfileResponse?> UpdateProfileAsync(int userId, UpdateProfileRequest request);
    Task<bool> ChangePasswordAsync(int userId, ChangePasswordRequest request);
}
