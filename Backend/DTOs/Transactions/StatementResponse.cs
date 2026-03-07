using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs.Transactions;

public class StatementResponse
{
    public string AccountNumber { get; set; } = null!;
    public string AccountHolderName { get; set; } = null!;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal OpeningBalance { get; set; }
    public decimal ClosingBalance { get; set; }
    public List<TransactionDto> Transactions { get; set; } = new List<TransactionDto>();
    public string Format { get; set; } = "PDF"; // PDF, CSV, or HTML
}