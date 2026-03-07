using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs.Transactions;

public class TransactionHistoryRequest
{
    [Required]
    public string AccountNumber { get; set; } = null!;
    
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}