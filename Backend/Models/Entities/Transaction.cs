using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Backend.Models.Constants;

namespace Backend.Models.Entities;

public class Transaction
{
    [Key]
    public int Id { get; set; }

    public int FromAccountId { get; set; }
    public int ToAccountId { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }

    public string Type { get; set; } = "Transfer";
    public string Status { get; set; } = TransactionStatuses.Completed;
    public bool RequiresApproval { get; set; }
    public string? BeneficiaryReference { get; set; }
    public string? SenderReference { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public int? ReviewedByAdminId { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public string? ReviewNote { get; set; }

    public Account? FromAccount { get; set; }
    public Account? ToAccount { get; set; }
}
