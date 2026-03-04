using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs.Accounts;

public class AccountCreateDto
{
    [Required]
    public int UserId { get; set; }

    [Required]
    [StringLength(50, MinimumLength = 2, ErrorMessage = "Account name must be between 2 and 50 characters.")]
    public string AccountName { get; set; } = null!;

    [Range(0.01, double.MaxValue, ErrorMessage = "Initial balance must be greater than 0")]
    public decimal InitialBalance { get; set; }
}
