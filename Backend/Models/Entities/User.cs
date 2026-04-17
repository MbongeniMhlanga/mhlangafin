using System.ComponentModel.DataAnnotations;
using Backend.Models.Constants;

namespace Backend.Models.Entities;

public class User
{
    [Key]
    public int Id { get; set; }
    [Required]
    public string FirstName { get; set; } = null!;
    [Required]
    public string LastName { get; set; } = null!;
    public string FullName => $"{FirstName} {LastName}";
    [Required]
    public string Email { get; set; } = null!;
    [Required]
    public string PasswordHash { get; set; } = null!;
    [Required]
    public string Role { get; set; } = UserRoles.Customer;
    [Required]
    public string Status { get; set; } = UserStatuses.Active;

    public ICollection<Account>? Accounts { get; set; }
    public ICollection<Beneficiary>? Beneficiaries { get; set; }
    public ICollection<AuditLog>? AuditLogs { get; set; }
}
