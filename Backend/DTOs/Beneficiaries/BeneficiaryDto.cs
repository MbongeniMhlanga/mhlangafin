namespace Backend.DTOs.Beneficiaries;

public class BeneficiaryDto
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public string AccountNumber { get; set; } = null!;
    public string? BankName { get; set; }
}

public class BeneficiaryCreateDto
{
    public string Name { get; set; } = null!;
    public string AccountNumber { get; set; } = null!;
    public string? BankName { get; set; }
    public int UserId { get; set; }
}
