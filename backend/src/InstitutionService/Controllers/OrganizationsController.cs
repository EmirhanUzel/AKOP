using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using InstitutionService.Constants;
using InstitutionService.Services;
using InstitutionService.DTOs;


namespace InstitutionService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class OrganizationsController : ControllerBase
{
    private readonly IOrganizationService _organizationService;

    public OrganizationsController(IOrganizationService organizationService)
    {
        _organizationService = organizationService;
    }

    [HttpGet]
    [Authorize(Policy = AuthorizationPolicyNames.SystemAdminOnly)]
    public async Task<IActionResult> GetAll()
    {
        var results = await _organizationService.GetAllAsync();

        return Ok(results);
    }


    [HttpGet("{id:guid}")]
    [Authorize(Policy = AuthorizationPolicyNames.SystemAdminOnly)]
    public async Task<IActionResult> GetById(Guid id)
    {
        var result = await _organizationService.GetByIdAsync(id);
        if (result == null)
        {
            return NotFound("Kurum bulunamadı");
        }
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Policy = AuthorizationPolicyNames.SystemAdminOnly)]

    public async Task<IActionResult> Create([FromBody] CreateOrganizationDto dto)
    {
        try
        {
            var result = await _organizationService.CreateAsync(dto);
            return CreatedAtAction(
                nameof(GetById),
                new {id = result.Id},
                result
            );
        }
        catch (KeyNotFoundException exception)
        {
            return BadRequest(exception.Message);
        }
        catch (InvalidOperationException exception)
        {
            return Conflict(exception.Message);
        }
    }

    [HttpGet("me")]
    [Authorize(Policy = AuthorizationPolicyNames.OrganizationMemberOnly)]
    public async Task<IActionResult> GetMyOrganization()
    {
        var institutionIdClaim = User.FindFirst("institutionId");
        var institutionIdValue = institutionIdClaim?.Value;
        if (!Guid.TryParse(institutionIdValue, out var institutionId))
        {
            return Forbid();
        }

        var result = await _organizationService.GetByIdAsync(institutionId);


        if (result == null)
        {
            return NotFound("Kurum bulunamadı");
        }
        return Ok(result);
    }


}
