namespace Backend.DTOs.Admin;

public class AdminTransactionDto
{
    public int Id { get; set; }
    public string Type { get; set; } = null!;
    public decimal Amount { get; set; }
    public string Status { get; set; } = null!;
    public bool RequiresApproval { get; set; }
    public string? FromAccountNumber { get; set; }
    public string? ToAccountNumber { get; set; }
    public int? FromUserId { get; set; }
    public int? ToUserId { get; set; }
    public string? BeneficiaryReference { get; set; }
    public string? SenderReference { get; set; }
    public DateTime Timestamp { get; set; }
    public int? ReviewedByAdminId { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public string? ReviewNote { get; set; }
}
