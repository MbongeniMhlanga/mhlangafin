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

    [HttpGet("history")]
    [Authorize]
    public async Task<IActionResult> GetTransactionHistory([FromQuery] TransactionHistoryRequest request)
    {
        var result = await _tx.GetTransactionHistoryAsync(request);
        return Ok(result);
    }

    [HttpPost("statement")]
    [Authorize]
    public async Task<IActionResult> GenerateStatement([FromBody] StatementRequest request)
    {
        var result = await _tx.GenerateStatementAsync(request);
        return Ok(result);
    }

    [HttpPost("statement/download")]
    [Authorize]
    public async Task<IActionResult> DownloadStatement([FromBody] StatementRequest request, [FromQuery] string format = "PDF")
    {
        var result = await _tx.GenerateStatementAsync(request, format);
        
        // Generate a simple text-based statement for now
        // In a real implementation, you would use a PDF library like iTextSharp or QuestPDF
        var statementText = GenerateStatementText(result);
        
        var fileName = $"Statement_{request.AccountNumber}_{request.StartDate:yyyyMMdd}_{request.EndDate:yyyyMMdd}.txt";
        
        return File(System.Text.Encoding.UTF8.GetBytes(statementText), "text/plain", fileName);
    }
    
    private string GenerateStatementText(StatementResponse statement)
    {
        var sb = new System.Text.StringBuilder();
        sb.AppendLine("========================================");
        sb.AppendLine("           MHLANGAFIN BANK");
        sb.AppendLine("           ACCOUNT STATEMENT");
        sb.AppendLine("========================================");
        sb.AppendLine();
        sb.AppendLine($"Account Number: {statement.AccountNumber}");
        sb.AppendLine($"Account Holder: {statement.AccountHolderName}");
        sb.AppendLine($"Statement Period: {statement.StartDate:dd MMM yyyy} to {statement.EndDate:dd MMM yyyy}");
        sb.AppendLine();
        sb.AppendLine("========================================");
        sb.AppendLine("TRANSACTIONS");
        sb.AppendLine("========================================");
        sb.AppendLine();
        
        foreach (var transaction in statement.Transactions)
        {
            sb.AppendLine($"{transaction.Timestamp:dd MMM yyyy HH:mm} | {transaction.Type,-10} | {transaction.Amount,12:C} | {transaction.FromAccountNumber} → {transaction.ToAccountNumber}");
        }
        
        sb.AppendLine();
        sb.AppendLine("========================================");
        sb.AppendLine($"Opening Balance: {statement.OpeningBalance:C}");
        sb.AppendLine($"Closing Balance: {statement.ClosingBalance:C}");
        sb.AppendLine("========================================");
        sb.AppendLine();
        sb.AppendLine("Thank you for banking with MhlangaFin!");
        
        return sb.ToString();
    }
}
