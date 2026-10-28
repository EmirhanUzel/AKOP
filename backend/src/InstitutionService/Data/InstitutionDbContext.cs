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

    public DbSet<Organization> Organizations { get; set; } = null!;

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

        modelBuilder.Entity<Organization>(entity =>
        {
            entity.HasKey(organization => organization.Id);

            entity.Property(organization => organization.Name)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(organization => organization.NormalizedName)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(organization => organization.City)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(organization => organization.ProfileInfo)
                .HasMaxLength(1000);

            entity.Property(organization => organization.CreatedAt)
                .IsRequired();

            entity.HasIndex(organization => new
                {
                    organization.NormalizedName,
                    organization.OrganizationTypeId,
                    organization.City
                })
                .IsUnique();

            entity.HasOne(organization => organization.OrganizationType)
                .WithMany()
                .HasForeignKey(organization => organization.OrganizationTypeId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
