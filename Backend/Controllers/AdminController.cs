using Backend.DTOs.Admin;
using Backend.Extensions;
using Backend.Models.Constants;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers;

[Authorize(Roles = UserRoles.Admin)]
[ApiController]
[Route("api/[controller]")]
public class AdminController : ControllerBase
{
    private readonly IAdminService _adminService;

    public AdminController(IAdminService adminService)
    {
        _adminService = adminService;
    }

    [HttpGet("users")]
    public async Task<ActionResult<IReadOnlyList<AdminUserDto>>> GetUsers()
    {
        return Ok(await _adminService.GetUsersAsync());
    }

    [HttpPatch("users/{id}/status")]
    public async Task<ActionResult<AdminUserDto>> UpdateUserStatus(int id, [FromBody] UpdateUserStatusRequest request)
    {
        if (!User.TryGetUserId(out var adminUserId))
            return Unauthorized();

        var result = await _adminService.UpdateUserStatusAsync(id, request.Status, adminUserId);
        if (result is null)
            return NotFound();

        return Ok(result);
    }

    [HttpPatch("accounts/{id}/status")]
    public async Task<ActionResult> UpdateAccountStatus(int id, [FromBody] UpdateAccountStatusRequest request)
    {
        if (!User.TryGetUserId(out var adminUserId))
            return Unauthorized();

        var result = await _adminService.UpdateAccountStatusAsync(id, request.Status, adminUserId);
        if (result is null)
            return NotFound();

        return Ok(result);
    }

    [HttpGet("transactions")]
    public async Task<ActionResult<IReadOnlyList<AdminTransactionDto>>> GetTransactions([FromQuery] string? status)
    {
        return Ok(await _adminService.GetTransactionsAsync(status));
    }

    [HttpPost("transactions/{id}/approve")]
    public async Task<ActionResult<AdminTransactionDto>> ApproveTransaction(int id, [FromBody] ReviewTransactionRequest request)
    {
        if (!User.TryGetUserId(out var adminUserId))
            return Unauthorized();

        var result = await _adminService.ApproveTransactionAsync(id, request.Note, adminUserId);
        return Ok(result);
    }

    [HttpPost("transactions/{id}/reject")]
    public async Task<ActionResult<AdminTransactionDto>> RejectTransaction(int id, [FromBody] ReviewTransactionRequest request)
    {
        if (!User.TryGetUserId(out var adminUserId))
            return Unauthorized();

        var result = await _adminService.RejectTransactionAsync(id, request.Note, adminUserId);
        return Ok(result);
    }

    [HttpPost("users/{id}/reset-password")]
    public async Task<ActionResult<ResetPasswordResponse>> ResetPassword(int id, [FromBody] ResetPasswordRequest request)
    {
        if (!User.TryGetUserId(out var adminUserId))
            return Unauthorized();

        return Ok(await _adminService.ResetUserPasswordAsync(id, request, adminUserId));
    }

    [HttpGet("stats")]
    public async Task<ActionResult<AdminStatsDto>> GetStats()
    {
        return Ok(await _adminService.GetStatsAsync());
    }
}
