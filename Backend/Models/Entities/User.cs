using System.ComponentModel.DataAnnotations;

namespace Backend.Models.Entities;

public class User
{
    [Key]
    public int Id { get; set; }
    [Required]
    public string FullName { get; set; } = null!;
    [Required]
    public string Email { get; set; } = null!;
    [Required]
    public string PasswordHash { get; set; } = null!; // replace with secure hashing in prod
    [Required]
    public string Role { get; set; } = "User";

    public ICollection<Account>? Accounts { get; set; }
    public ICollection<AuditLog>? AuditLogs { get; set; }
}
