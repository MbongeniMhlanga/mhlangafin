namespace Backend.DTOs.Admin;

public class ResetPasswordResponse
{
    public int UserId { get; set; }
    public string TemporaryPassword { get; set; } = null!;
}
