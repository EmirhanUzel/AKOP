using System.Text;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

using ReportService.Classification;
using ReportService.Constants;
using ReportService.Data;
using ReportService.ModelBinding;

using ReportService.Repositories;
using ReportService.Services;
using ReportService.Storage;


var builder = WebApplication.CreateBuilder(args);

// Controller servisleri
builder.Services.AddControllers(options =>
{
    // Form alanlarındaki sayılar (enlem/boylam) kültürden bağımsız okunur
    var formFactoryIndex = options.ValueProviderFactories
        .IndexOf(options.ValueProviderFactories.OfType<FormValueProviderFactory>().Single());

    options.ValueProviderFactories[formFactoryIndex] = new InvariantCultureFormValueProviderFactory();
});

// OpenAPI
builder.Services.AddOpenApi();

// PostgreSQL ve Entity Framework Core
builder.Services.AddDbContext<ReportDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("ReportDb"),
        // PostGIS: konum kolonu ve yakınlık sorguları için
        npgsql => npgsql.UseNetTopologySuite()
    )
);

builder.Services.AddScoped<IReportRepository, ReportRepository>();
builder.Services.AddScoped<IReportService, ReportService.Services.ReportService>();

// Fotoğraf dosyaları (şimdilik disk; ileride S3 uyumlu depolama)
builder.Services.AddSingleton<IFileStorage, DiskFileStorage>();

// Fotoğraftan kategori önerisi (ONNX modeli bir kez yüklenir, tüm isteklerde paylaşılır)
builder.Services.AddSingleton<ICategoryClassifier, OnnxCategoryClassifier>();
builder.Services.AddScoped<ICategorySuggestionService, CategorySuggestionService>();

var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("JWT anahtarı bulunamadı.");

var jwtIssuer = builder.Configuration["Jwt:Issuer"]
    ?? throw new InvalidOperationException("JWT Issuer bulunamadı.");

var jwtAudience = builder.Configuration["Jwt:Audience"]
    ?? throw new InvalidOperationException("JWT Audience bulunamadı.");

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,
            ValidateAudience = true,
            ValidAudience = jwtAudience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtKey)
            ),
            RequireSignedTokens = true,
            ValidateLifetime = true,
            RequireExpirationTime = true,
            ClockSkew = TimeSpan.Zero,
            RoleClaimType = System.Security.Claims.ClaimTypes.Role,
            NameClaimType = System.Security.Claims.ClaimTypes.NameIdentifier
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(
        AuthorizationPolicyNames.CitizenOnly,
        policy => policy.RequireRole(RoleNames.Citizen)
    );
});

var app = builder.Build();

// Model ilk istekte değil, açılışta yüklensin (~350 MB)
app.Services.GetRequiredService<ICategoryClassifier>();

// Development ortamında OpenAPI
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.Run();
