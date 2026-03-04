using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs.Accounts;

public class AccountCreateDto
{
    [Required]
    public int UserId { get; set; }

    [Required]
    [StringLength(20, MinimumLength = 5)]
    public string AccountNumber { get; set; } = null!;

    [Range(0.01, double.MaxValue, ErrorMessage = "Initial balance must be greater than 0")]
    public decimal InitialBalance { get; set; }
}
