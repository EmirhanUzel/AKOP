
namespace IdentityService.DTOs;

public class AuthResponseDto
{
    public string AccessToken { get; set; } = "";

    public string Role { get; set; } = "";

    public DateTime ExpiresAtUtc { get; set; }

}