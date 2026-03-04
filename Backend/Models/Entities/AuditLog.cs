using System.ComponentModel.DataAnnotations;

namespace Backend.Models.Entities;

public class AuditLog
{
    [Key]
    public int Id { get; set; }
    public int? UserId { get; set; }
    public string Action { get; set; } = null!;
    public string? Details { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
