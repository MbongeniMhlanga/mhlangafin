using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs.Transactions;

public class TransferRequest
{
    [Required]
    public string FromAccountNumber { get; set; } = null!;

    [Required]
    public string ToAccountNumber { get; set; } = null!;

    [Range(0.01, (double)decimal.MaxValue, ErrorMessage = "Transfer amount must be greater than zero.")]
    public decimal Amount { get; set; }
    
    public string? BeneficiaryReference { get; set; }
    public string? SenderReference { get; set; }
}
