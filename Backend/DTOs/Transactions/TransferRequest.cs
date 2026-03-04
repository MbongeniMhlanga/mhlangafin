using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs.Transactions;

public class TransferRequest
{
    [Required]
    public int FromAccountId { get; set; }

    [Required]
    public int ToAccountId { get; set; }

    [Range(0.01, (double)decimal.MaxValue, ErrorMessage = "Transfer amount must be greater than zero.")]
    public decimal Amount { get; set; }
}
