using Backend.DTOs.Beneficiaries;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Backend.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class BeneficiariesController : ControllerBase
{
    private readonly IBeneficiaryService _beneficiaryService;

    public BeneficiariesController(IBeneficiaryService beneficiaryService)
    {
        _beneficiaryService = beneficiaryService;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<BeneficiaryDto>>> GetMyBeneficiaries()
    {
        var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdString, out int userId)) return Unauthorized();

        var beneficiaries = await _beneficiaryService.GetByUserIdAsync(userId);
        return Ok(beneficiaries);
    }

    [HttpPost]
    public async Task<ActionResult<BeneficiaryDto>> AddBeneficiary(BeneficiaryCreateDto dto)
    {
        var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdString, out int userId)) return Unauthorized();

        dto.UserId = userId;
        var result = await _beneficiaryService.AddAsync(dto);
        return Ok(result);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteBeneficiary(int id)
    {
        var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdString, out int userId)) return Unauthorized();

        var success = await _beneficiaryService.DeleteAsync(id, userId);
        if (!success) return NotFound();

        return NoContent();
    }
}
