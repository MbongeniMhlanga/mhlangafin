using Microsoft.AspNetCore.Mvc;
using Backend.Services;
using Backend.DTOs.Accounts;
using Microsoft.AspNetCore.Authorization;

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
        var acc = await _accounts.GetByIdAsync(id);
        if (acc is null) return NotFound();
        return Ok(acc);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,User")]
    public async Task<IActionResult> Create([FromBody] AccountCreateDto dto)
    {
        var created = await _accounts.CreateAsync(dto);
        return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
    }
}
