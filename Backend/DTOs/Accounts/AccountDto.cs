namespace Backend.DTOs.Accounts;

public class AccountDto
{
    public int Id { get; set; }
    public string AccountName { get; set; } = null!;
    public string AccountNumber { get; set; } = null!;
    public decimal Balance { get; set; }
    public bool IsMain { get; set; }
    public string Status { get; set; } = null!;
    public string? ExpiryDate { get; set; }
    public string? CVV { get; set; }
}
