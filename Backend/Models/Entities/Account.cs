using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models.Entities;

public class Account
{
    [Key]
    public int Id { get; set; }
    [Required]
    public string AccountName { get; set; } = null!;
    [Required]
    public string AccountNumber { get; set; } = null!;
    [Column(TypeName = "decimal(18,2)")]
    public decimal Balance { get; set; }
    public int UserId { get; set; }
    public bool IsMain { get; set; }
    public string Status { get; set; } = "Active";
    
    // Digital Card Details (populated for Main Account)
    public string? ExpiryDate { get; set; }
    public string? CVV { get; set; }

    public User? User { get; set; }

    public ICollection<Transaction>? SentTransactions { get; set; }
    public ICollection<Transaction>? ReceivedTransactions { get; set; }
}
