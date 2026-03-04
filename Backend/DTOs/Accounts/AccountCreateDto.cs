namespace Backend.DTOs.Accounts;

public class AccountCreateDto
{
    public int UserId { get; set; }
    public string AccountNumber { get; set; } = null!;
    public decimal InitialBalance { get; set; }
}
