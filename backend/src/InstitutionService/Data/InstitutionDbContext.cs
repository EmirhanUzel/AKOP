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

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<OrganizationType>(entity =>
        {
            entity.Property(organizationType => organizationType.Name)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(organizationType => organizationType.NormalizedName)
                .IsRequired()
                .HasMaxLength(100);

            entity.HasIndex(organizationType => organizationType.NormalizedName)
                .IsUnique();
        });
    }
}
