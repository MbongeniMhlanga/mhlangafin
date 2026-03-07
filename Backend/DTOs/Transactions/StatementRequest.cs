using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs.Transactions;

public class StatementRequest
{
    [Required]
    public string AccountNumber { get; set; } = null!;
    
    [Required]
    public DateTime StartDate { get; set; }
    
    [Required]
    public DateTime EndDate { get; set; }
}