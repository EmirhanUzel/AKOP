using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using IdentityService.Clients;
using IdentityService.Constants;
using IdentityService.DTOs;
using IdentityService.Services;
namespace IdentityService.Controllers;
using System.Security.Claims;


[ApiController]
[Authorize]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly UserService _userService;
    private readonly IOrganizationClient _organizationClient;

    public UsersController(
        UserService userService,
        IOrganizationClient organizationClient)
    {
        _userService = userService;
        _organizationClient = organizationClient;
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

    [HttpPut("me/password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto dto)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (userId == null)
        {
            return Unauthorized("Kullanıcı bulunamadı.");
        }

        var result = await _userService.ChangePasswordAsync(userId, dto);

        if (!result.Succeeded)
        {
            return BadRequest(result.Errors);
        }

        return NoContent();
    }

    [HttpPost("institution")]
    [Authorize(Policy = AuthorizationPolicyNames.SystemAdminOnly)]
    public async Task<IActionResult> CreateInstitutionUser([FromBody] CreateInstitutionUserDto dto)
    {
        var authorizationHeader = Request.Headers.Authorization.ToString();

        try
        {
            var organizationExists = await _organizationClient.ExistsAsync(
                dto.InstitutionId,
                authorizationHeader,
                HttpContext.RequestAborted
            );

            if (!organizationExists)
            {
                return BadRequest("Kurum bulunamadı.");
            }
        }
        catch (HttpRequestException)
        {
            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                "Kurum servisine ulaşılamadı."
            );
        }

        var result = await _userService.CreateInstitutionUserAsync(dto);

        if (!result.Succeeded)
        {
            return BadRequest(result.Errors);
        }

        return StatusCode(
            StatusCodes.Status201Created,
            "Kurum kullanıcısı oluşturuldu."
        );
    }

    [HttpPost("my-institution/field-staff")]
    [Authorize(Policy = AuthorizationPolicyNames.OrgManagerOnly)]
    public async Task<IActionResult> CreateFieldStaff([FromBody] CreateFieldStaffDto dto)
    {
        var institutionIdValue = User.FindFirstValue("institutionId");

        if (!Guid.TryParse(institutionIdValue, out var institutionId))
        {
            return Forbid();
        }

        var authorizationHeader = Request.Headers.Authorization.ToString();

        try
        {
            var organizationExists = await _organizationClient
                .CurrentOrganizationExistsAsync(
                    authorizationHeader,
                    HttpContext.RequestAborted
                );

            if (!organizationExists)
            {
                return BadRequest("Kurum bulunamadı.");
            }
        }
        catch (HttpRequestException)
        {
            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                "Kurum servisine ulaşılamadı."
            );
        }

        var result = await _userService.CreateFieldStaffAsync(
            dto,
            institutionId
        );

        if (!result.Succeeded)
        {
            return BadRequest(result.Errors);
        }

        return StatusCode(
            StatusCodes.Status201Created,
            "Saha personeli oluşturuldu."
        );
    }

}
