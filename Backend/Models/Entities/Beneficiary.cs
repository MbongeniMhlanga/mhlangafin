using System.ComponentModel.DataAnnotations;

namespace Backend.Models.Entities;

public class Beneficiary
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public string Name { get; set; } = null!;
    
    [Required]
    public string AccountNumber { get; set; } = null!;
    
    public string? BankName { get; set; }
    
    public int UserId { get; set; }
    public User? User { get; set; }
}
