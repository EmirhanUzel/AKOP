using Microsoft.EntityFrameworkCore;
using InstitutionService.Models;

namespace InstitutionService.Data;

public class InstitutionDbContext : DbContext
{
    public InstitutionDbContext(DbContextOptions<InstitutionDbContext> options)
        : base(options)
    {
    }

    public DbSet<OrganizationType> OrganizationTypes { get; set; } = null!;
}