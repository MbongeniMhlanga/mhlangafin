using Microsoft.AspNetCore.Mvc;
using Backend.Services;
using Backend.DTOs.Accounts;
using Microsoft.AspNetCore.Authorization;
using Backend.Extensions;
using Backend.Models.Constants;

namespace Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AccountsController : ControllerBase
{
    private readonly IAccountService _accounts;
    public AccountsController(IAccountService accounts) => _accounts = accounts;

    [HttpGet("{id}")]
    [Authorize]
    public async Task<IActionResult> Get(int id)
    {
        if (!User.TryGetUserId(out var userId))
            return Unauthorized();

        var acc = await _accounts.GetByIdAsync(id, userId, User.IsAdmin());
        if (acc is null) return NotFound();
        return Ok(acc);
    }

    [HttpGet("my")]
    [Authorize]
    public async Task<IActionResult> GetMyAccounts()
    {
        if (!User.TryGetUserId(out var userId))
            return Unauthorized();

        var accounts = await _accounts.GetByUserIdAsync(userId);
        return Ok(accounts);
    }

    [HttpPost]
    [Authorize(Roles = UserRoles.AdminOrCustomer)]
    public async Task<IActionResult> Create([FromBody] AccountCreateDto dto)
    {
        if (!User.TryGetUserId(out var userId))
            return Unauthorized();

        var created = await _accounts.CreateAsync(dto, userId, User.IsAdmin());
        return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
    }
}
