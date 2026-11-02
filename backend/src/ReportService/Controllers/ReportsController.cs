using System.Security.Claims;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

using ReportService.Constants;
using ReportService.DTOs;
using ReportService.Services;

namespace ReportService.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AuthorizationPolicyNames.CitizenOnly)]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;

    public ReportsController(IReportService reportService)
    {
        _reportService = reportService;
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateReportDto dto)
    {
        var citizenId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrEmpty(citizenId))
        {
            return Unauthorized();
        }

        var result = await _reportService.CreateAsync(dto, citizenId);

        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpGet("mine")]
    public async Task<IActionResult> GetMine()
    {
        var citizenId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrEmpty(citizenId))
        {
            return Unauthorized();
        }

        var result = await _reportService.GetMineAsync(citizenId);

        return Ok(result);
    }
}