using System.Security.Claims;
using Backend.Models.Constants;

namespace Backend.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static bool TryGetUserId(this ClaimsPrincipal user, out int userId)
    {
        var userIdString = user.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.TryParse(userIdString, out userId);
    }

    public static bool IsAdmin(this ClaimsPrincipal user)
    {
        var role = user.FindFirstValue(ClaimTypes.Role);
        return string.Equals(role, UserRoles.Admin, StringComparison.OrdinalIgnoreCase);
    }
}
