using Microsoft.AspNetCore.Identity;

namespace IdentityService.Models;


public class AppUser : IdentityUser
{
    public string FullName { get; set; } = "";
    
    public DateTime CreatedAt {get; set;} = DateTime.UtcNow;

    public Guid? InstitutionId { get; set; }

}