using Microsoft.AspNetCore.Mvc;
using Backend.Services;
using Backend.DTOs.Auth;
using Microsoft.AspNetCore.Authorization;
using Backend.Extensions;

namespace Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _auth;
    public AuthController(IAuthService auth) => _auth = auth;

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var result = await _auth.AuthenticateAsync(request);
        if (result is null) return Unauthorized();
        return Ok(result);
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        var success = await _auth.RegisterAsync(request);
        if (!success) return BadRequest(new { message = "User with this email already exists." });
        return Ok(new { message = "Registration successful" });
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> GetProfile()
    {
        if (!User.TryGetUserId(out var userId))
            return Unauthorized();

        var profile = await _auth.GetProfileAsync(userId);
        if (profile is null) return NotFound();

        return Ok(profile);
    }

    [HttpPatch("me")]
    [Authorize]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        if (!User.TryGetUserId(out var userId))
            return Unauthorized();

        var profile = await _auth.UpdateProfileAsync(userId, request);
        if (profile is null)
            return Conflict(new { message = "Email address is already in use or profile was not found." });

        return Ok(profile);
    }

    [HttpPatch("me/password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        if (!User.TryGetUserId(out var userId))
            return Unauthorized();

        var changed = await _auth.ChangePasswordAsync(userId, request);
        if (!changed)
            return BadRequest(new { message = "Current password is incorrect or password could not be updated." });

        return Ok(new { message = "Password updated successfully." });
    }
}
