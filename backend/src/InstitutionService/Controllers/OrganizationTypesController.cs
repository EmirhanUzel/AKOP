using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using InstitutionService.Constants;
using InstitutionService.Services;
using InstitutionService.DTOs;

namespace InstitutionService.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AuthorizationPolicyNames.SystemAdminOnly)]
public class OrganizationTypesController : ControllerBase
{
    private readonly IOrganizationTypeService _organizationTypeService;
    public OrganizationTypesController(IOrganizationTypeService organizationTypeService)
    {
        _organizationTypeService = organizationTypeService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var results = await _organizationTypeService.GetAllAsync();
        return Ok(results);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var result = await _organizationTypeService.GetByIdAsync(id);
        if (result == null)
        {
            return NotFound("Kurum türü bulunamadı");
        }

        return Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateOrganizationTypeDto dto)
    {
        try
        {
            var createdOrganizationType = await _organizationTypeService.CreateAsync(dto);

            return CreatedAtAction(
                nameof(GetById),
                new { id = createdOrganizationType.Id },
                createdOrganizationType
            );
        }
        catch (InvalidOperationException exception)
        {
            return Conflict(exception.Message);
        }
    }
}
