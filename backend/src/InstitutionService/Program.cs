using InstitutionService.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Controller servisleri
builder.Services.AddControllers();

// OpenAPI
builder.Services.AddOpenApi();

// PostgreSQL ve Entity Framework Core
builder.Services.AddDbContext<InstitutionDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("InstitutionDb")
    )
);

var app = builder.Build();

// Development ortamında OpenAPI
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();