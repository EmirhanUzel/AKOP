using Microsoft.EntityFrameworkCore;
using ReportService.Models;

namespace ReportService.Data;

public class ReportDbContext : DbContext
{
    public ReportDbContext(DbContextOptions<ReportDbContext> options)
        : base(options)
    {
    }

    public DbSet<Report> Reports { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Report>(entity =>
        {
            entity.HasKey(report => report.Id);

            entity.Property(report => report.CitizenId)
                .IsRequired()
                .HasMaxLength(450);

            entity.Property(report => report.Title)
                .HasMaxLength(120);

            entity.Property(report => report.Description)
                .IsRequired()
                .HasMaxLength(2000);

            entity.Property(report => report.CategoryCode)
                .HasMaxLength(50);

            entity.Property(report => report.LocationDescription)
                .HasMaxLength(300);

            entity.Property(report => report.Status)
                .IsRequired()
                .HasConversion<string>()
                .HasMaxLength(20);

            entity.Property(report => report.CreatedAt)
                .IsRequired();

            entity.HasIndex(report => new
            {
                report.CitizenId,
                report.CreatedAt
            });
        });
    }
}
