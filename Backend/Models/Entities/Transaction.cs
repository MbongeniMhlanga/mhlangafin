using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

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
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public Account? FromAccount { get; set; }
    public Account? ToAccount { get; set; }
}
