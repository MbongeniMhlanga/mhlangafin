using Microsoft.AspNetCore.Mvc;
using Backend.Services;
using Backend.DTOs.Transactions;
using Microsoft.AspNetCore.Authorization;

namespace Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TransactionsController : ControllerBase
{
    private readonly ITransactionService _tx;
    public TransactionsController(ITransactionService tx) => _tx = tx;

    [HttpPost("transfer")]
    [Authorize]
    public async Task<IActionResult> Transfer([FromBody] TransferRequest request)
    {
        var result = await _tx.TransferAsync(request);
        if (result.Status == "Success") return Ok(result);
        return BadRequest(result);
    }
}
