using Microsoft.AspNetCore.Identity;
using IdentityService.Models;
using IdentityService.DTOs;
namespace IdentityService.Services;

public class UserService
{
    private readonly UserManager<AppUser> _userManager;

    public UserService(UserManager<AppUser> userManager)
    {
        _userManager = userManager;

    }

    public async Task<MeResponseDto?> GetMyProfileAsync(string userId)
    {
        var user = await _userManager.FindByIdAsync(userId);
    
        if (user == null)
        {
            return null;
        }

        var roles = await _userManager.GetRolesAsync(user);

        if (roles.Count != 1)
        {
            return null;
        }

        var role = roles[0];
        
        var profileDto = new MeResponseDto{
            FirstName = user.FirstName,
            LastName = user.LastName,
            Email = user.Email ?? "",
            Role = role
        };
        return profileDto;

    }


}