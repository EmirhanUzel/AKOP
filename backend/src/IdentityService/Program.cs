using IdentityService.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// PostgreSQL bağlantı bilgisini al
var connectionString = builder.Configuration.GetConnectionString("IdentityDb")
    ?? throw new InvalidOperationException(
        "IdentityDb veritabanı bağlantısı bulunamadı."
    );

// DbContext'i Dependency Injection sistemine ekle
builder.Services.AddDbContext<AppIdentityDbContext>(options =>
{
    options.UseNpgsql(connectionString);
});

// Controller servislerini ekle
builder.Services.AddControllers();

// OpenAPI desteği
builder.Services.AddOpenApi();

var app = builder.Build();

// Development ortamında OpenAPI
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// HTTP isteklerini HTTPS'e yönlendir
app.UseHttpsRedirection();

// Yetkilendirme middleware'i
app.UseAuthorization();

// Controller endpoint'lerini tanımla
app.MapControllers();

app.Run();