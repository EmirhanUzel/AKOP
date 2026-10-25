namespace IdentityService.Models;

public class RefreshToken
{
    public Guid Id { get; set; }
    public string UserId { get; set; } = "";

    public string TokenHash { get; set; } = "";

    public DateTime CreatedAtUtc {get; set;}

    public DateTime ExpiresAtUtc {get; set;}

    public DateTime? RevokedAtUtc {get; set;}

    public AppUser User { get; set; } = null!;
}