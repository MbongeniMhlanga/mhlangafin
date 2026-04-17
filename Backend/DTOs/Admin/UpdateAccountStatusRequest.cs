using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs.Admin;

public class UpdateAccountStatusRequest
{
    [Required]
    public string Status { get; set; } = null!;
}
