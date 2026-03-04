using Microsoft.AspNetCore.Mvc;
using Backend.Services;
using Backend.DTOs.Auth;

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
}
