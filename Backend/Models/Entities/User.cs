using System.ComponentModel.DataAnnotations;

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
    public string Role { get; set; } = "User";

    public ICollection<Account>? Accounts { get; set; }
    public ICollection<AuditLog>? AuditLogs { get; set; }
}
