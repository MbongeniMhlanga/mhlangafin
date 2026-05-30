using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs.Auth;

public class ChangePasswordRequest
{
    [Required]
    public string CurrentPassword { get; set; } = null!;

    [Required]
    [StringLength(100, MinimumLength = 6)]
    public string NewPassword { get; set; } = null!;
}
