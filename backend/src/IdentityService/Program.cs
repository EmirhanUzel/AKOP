using System.Text;

using IdentityService.Data;
using IdentityService.Models;
using IdentityService.Services;

using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);


// ========================================
// 1. POSTGRESQL BAĞLANTISI
// ========================================

var connectionString = builder.Configuration.GetConnectionString("IdentityDb")
    ?? throw new InvalidOperationException(
        "IdentityDb veritabanı bağlantısı bulunamadı."
    );

builder.Services.AddDbContext<AppIdentityDbContext>(options =>
{
    options.UseNpgsql(connectionString);
});


// ========================================
// 2. ASP.NET CORE IDENTITY
// ========================================

builder.Services
    .AddIdentityCore<AppUser>(options =>
    {
        options.User.RequireUniqueEmail = true;
    })
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<AppIdentityDbContext>()
    .AddSignInManager();


// ========================================
// 3. DEPENDENCY INJECTION
// ========================================

builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<TokenService>();


// ========================================
// 4. JWT YAPILANDIRMA BİLGİLERİ
// ========================================

var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException(
        "JWT anahtarı bulunamadı."
    );

var jwtIssuer = builder.Configuration["Jwt:Issuer"]
    ?? throw new InvalidOperationException(
        "JWT Issuer bulunamadı."
    );

var jwtAudience = builder.Configuration["Jwt:Audience"]
    ?? throw new InvalidOperationException(
        "JWT Audience bulunamadı."
    );


// ========================================
// 5. JWT AUTHENTICATION
// ========================================

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            // Token'ı oluşturan sistemi doğrula
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,

            // Token'ın hedef sistemini doğrula
            ValidateAudience = true,
            ValidAudience = jwtAudience,

            // Token'ın imzasını doğrula
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtKey)
            ),

            // İmzalı token zorunlu olsun
            RequireSignedTokens = true,

            // Token süresini kontrol et
            ValidateLifetime = true,
            RequireExpirationTime = true,

            // Saat toleransı
            ClockSkew = TimeSpan.Zero,

            // Rol ve kullanıcı kimliği claim'leri
            RoleClaimType = System.Security.Claims.ClaimTypes.Role,
            NameClaimType = System.Security.Claims.ClaimTypes.NameIdentifier
        };
    });


// ========================================
// 6. AUTHORIZATION
// ========================================

builder.Services.AddAuthorization();


// ========================================
// 7. CONTROLLERS VE OPENAPI
// ========================================

builder.Services.AddControllers();

builder.Services.AddOpenApi();


// ========================================
// 8. UYGULAMAYI OLUŞTUR
// ========================================

var app = builder.Build();


// ========================================
// 9. ROLE SEEDING
// ========================================

using (var scope = app.Services.CreateScope())
{
    var roleManager = scope.ServiceProvider
        .GetRequiredService<RoleManager<IdentityRole>>();

    await RoleSeeder.SeedRolesAsync(roleManager);
}


// ========================================
// 10. OPENAPI
// ========================================

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}


// ========================================
// 11. MIDDLEWARE
// ========================================

app.UseHttpsRedirection();

// Önce kullanıcının kimliğini doğrula
app.UseAuthentication();

// Sonra kullanıcının yetkilerini kontrol et
app.UseAuthorization();


// ========================================
// 12. CONTROLLER ENDPOINTLERİ
// ========================================

app.MapControllers();


// ========================================
// 13. UYGULAMAYI BAŞLAT
// ========================================

app.Run();