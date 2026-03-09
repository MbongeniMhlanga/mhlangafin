using Microsoft.AspNetCore.Mvc;
using Backend.Services;
using Backend.DTOs.Transactions;
using Microsoft.AspNetCore.Authorization;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

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
        try
        {
            var result = await _tx.GenerateStatementAsync(request, format);
            
            // Generate PDF using QuestPDF
            var pdfBytes = GenerateStatementPDF(result);
            
            var fileName = $"Statement_{request.AccountNumber}_{request.StartDate:yyyyMMdd}_{request.EndDate:yyyyMMdd}.pdf";
            
            // Return as PDF with proper headers for download
            return File(pdfBytes, "application/pdf", fileName);
        }
        catch (Exception ex)
        {
            // Log the error and return a simple error message
            return StatusCode(500, new { error = "Failed to generate statement", message = ex.Message });
        }
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

    private byte[] GenerateStatementPDF(StatementResponse statement)
    {
        // Configure QuestPDF
        QuestPDF.Settings.License = LicenseType.Community;

        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(2, Unit.Centimetre);
                page.DefaultTextStyle(x => x.FontSize(12));
                
                page.Header().Row(row =>
                {
                    row.ConstantItem(100).Height(50).Placeholder();
                    row.RelativeItem().Column(column =>
                    {
                        column.Item().AlignRight().Text("MHLANGAFIN BANK").SemiBold().FontSize(20);
                        column.Item().AlignRight().Text("ACCOUNT STATEMENT").FontSize(14).FontColor(Colors.Grey.Medium);
                    });
                });

                page.Content().Column(column =>
                {
                    // Account Information
                    column.Item().PaddingVertical(10).Column(accountColumn =>
                    {
                        accountColumn.Item().Text($"Account Number: {statement.AccountNumber}").FontSize(14);
                        accountColumn.Item().Text($"Account Holder: {statement.AccountHolderName}").FontSize(14);
                        accountColumn.Item().Text($"Statement Period: {statement.StartDate:dd MMM yyyy} to {statement.EndDate:dd MMM yyyy}").FontSize(14);
                    });

                    // Balance Summary
                    column.Item().PaddingVertical(10).Grid(grid =>
                    {
                        grid.Columns(4);
                        grid.Spacing(10);
                        
                        grid.Item().Background(Colors.Grey.Lighten3).Padding(10).Column(col =>
                        {
                            col.Item().Text("Total Transactions").FontSize(10).FontColor(Colors.Grey.Darken1);
                            col.Item().Text(statement.Transactions.Count.ToString()).FontSize(16).SemiBold();
                        });
                        
                        grid.Item().Background(Colors.Grey.Lighten3).Padding(10).Column(col =>
                        {
                            col.Item().Text("Statement Period").FontSize(10).FontColor(Colors.Grey.Darken1);
                            col.Item().Text($"{statement.StartDate:MMM yyyy}").FontSize(16).SemiBold();
                        });
                        
                        grid.Item().Background(Colors.Grey.Lighten3).Padding(10).Column(col =>
                        {
                            col.Item().Text("Opening Balance").FontSize(10).FontColor(Colors.Grey.Darken1);
                            col.Item().Text(statement.OpeningBalance.ToString("C")).FontSize(16).SemiBold();
                        });
                        
                        grid.Item().Background(Colors.Grey.Lighten3).Padding(10).Column(col =>
                        {
                            col.Item().Text("Closing Balance").FontSize(10).FontColor(Colors.Grey.Darken1);
                            col.Item().Text(statement.ClosingBalance.ToString("C")).FontSize(16).SemiBold();
                        });
                    });

                    // Transactions Table
                    column.Item().PaddingVertical(10).Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.ConstantColumn(100);
                            columns.ConstantColumn(100);
                            columns.ConstantColumn(100);
                            columns.RelativeColumn();
                            columns.ConstantColumn(100);
                        });

                        table.Header(header =>
                        {
                            header.Cell().Background(Colors.Blue.Lighten2).Padding(5).Text("Date & Time").SemiBold();
                            header.Cell().Background(Colors.Blue.Lighten2).Padding(5).Text("Type").SemiBold();
                            header.Cell().Background(Colors.Blue.Lighten2).Padding(5).Text("Amount").SemiBold();
                            header.Cell().Background(Colors.Blue.Lighten2).Padding(5).Text("Description").SemiBold();
                            header.Cell().Background(Colors.Blue.Lighten2).Padding(5).Text("Balance").SemiBold();
                        });

                        foreach (var transaction in statement.Transactions)
                        {
                            table.Cell().BorderBottom(0.5f).BorderColor(Colors.Grey.Medium).Padding(5).Text(transaction.Timestamp.ToString("dd MMM yyyy HH:mm"));
                            table.Cell().BorderBottom(0.5f).BorderColor(Colors.Grey.Medium).Padding(5).Text(transaction.Type);
                            table.Cell().BorderBottom(0.5f).BorderColor(Colors.Grey.Medium).Padding(5).Text(transaction.Amount.ToString("C")).AlignRight();
                            table.Cell().BorderBottom(0.5f).BorderColor(Colors.Grey.Medium).Padding(5).Text($"{transaction.FromAccountNumber} → {transaction.ToAccountNumber}");
                            table.Cell().BorderBottom(0.5f).BorderColor(Colors.Grey.Medium).Padding(5).Text(transaction.BalanceAfter.ToString("C")).AlignRight();
                        }
                    });

                    // Footer
                    column.Item().PaddingVertical(20).AlignCenter().Text("Thank you for banking with MhlangaFin!")
                        .FontSize(14).FontColor(Colors.Blue.Medium);
                });

                page.Footer().AlignCenter().Text(x =>
                {
                    x.Span("Page ").FontSize(10);
                    x.CurrentPageNumber().FontSize(10);
                    x.Span(" of ").FontSize(10);
                    x.TotalPages().FontSize(10);
                });
            });
        });

        using var stream = new MemoryStream();
        document.GeneratePdf(stream);
        return stream.ToArray();
    }
}
