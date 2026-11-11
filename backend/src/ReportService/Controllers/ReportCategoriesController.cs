using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

using ReportService.Services;

namespace ReportService.Controllers;

// Kategori listesi her giriş yapmış kullanıcıya açık; ReportsController ise yalnızca vatandaşlara
[ApiController]
[Route("api/Reports/categories")]
[Authorize]
public class ReportCategoriesController : ControllerBase
{
    private readonly IReportService _reportService;

    public ReportCategoriesController(IReportService reportService)
    {
        _reportService = reportService;
    }

    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok(_reportService.GetCategories());
    }
}
