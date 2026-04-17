using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs.Admin;

public class UpdateUserStatusRequest
{
    [Required]
    public string Status { get; set; } = null!;
}
