using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using IdentityService.Services;
namespace IdentityService.Controllers;
using System.Security.Claims;


[ApiController]
[Authorize]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly UserService _userService;

    public UsersController(UserService userService)
    {
        _userService = userService;
    }

    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var userID = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (userID == null)
        {
            return Unauthorized("Kullanıcı Bulunamadı");

        }
        var result = await _userService.GetMyProfileAsync(userID);
        
        if (result == null)
        {
            return Unauthorized("Kullanıcı veya Rolü Bulunamadı");
        }
        return Ok(result);
    }


}