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
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(ReportImageLimits.MaxRequestSizeBytes)]
    [RequestFormLimits(MultipartBodyLengthLimit = ReportImageLimits.MaxRequestSizeBytes)]
    public async Task<IActionResult> Create([FromForm] CreateReportDto dto)
    {
        var citizenId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrEmpty(citizenId))
        {
            return Unauthorized();
        }

        try
        {
            var result = await _reportService.CreateAsync(dto, citizenId);

            return StatusCode(StatusCodes.Status201Created, result);
        }
        catch (ArgumentException exception)
        {
            return BadRequest(exception.Message);
        }
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

    [HttpGet("{reportId:guid}")]
    public async Task<IActionResult> GetById(Guid reportId)
    {
        var citizenId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrEmpty(citizenId))
        {
            return Unauthorized();
        }

        var result = await _reportService.GetMineByIdAsync(reportId, citizenId);

        // Başkasının ihbarı da 404: ihbarın var olduğu bilgisi sızmaz
        if (result == null)
        {
            return NotFound();
        }

        return Ok(result);
    }

    [HttpGet("{reportId:guid}/images/{imageId:guid}")]
    public async Task<IActionResult> GetImage(Guid reportId, Guid imageId)
    {
        var citizenId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrEmpty(citizenId))
        {
            return Unauthorized();
        }

        var image = await _reportService.GetImageAsync(reportId, imageId, citizenId);

        // Başkasının fotoğrafı da 404: fotoğrafın var olduğu bilgisi sızmaz
        if (image == null)
        {
            return NotFound();
        }

        return File(image.Content, image.ContentType);
    }
}