using System.Text;

using InstitutionService.Constants;
using InstitutionService.Data;
using InstitutionService.Repositories;
using InstitutionService.Services;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

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


builder.Services.AddScoped<
    IOrganizationTypeRepository,
    OrganizationTypeRepository
>();

builder.Services.AddScoped<
    IOrganizationTypeService,
    OrganizationTypeService
>();

builder.Services.AddScoped<
    IOrganizationRepository,
    OrganizationRepository
>();

builder.Services.AddScoped<
    IOrganizationService,
    OrganizationService
>();

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
        AuthorizationPolicyNames.SystemAdminOnly,
        policy => policy.RequireRole(RoleNames.SystemAdmin)
    );

    options.AddPolicy(
        AuthorizationPolicyNames.OrganizationMemberOnly,
        policy =>
        {
            policy.RequireRole(RoleNames.OrgManager, RoleNames.FieldStaff);
            policy.RequireClaim("institutionId");
        }
    );
});

var app = builder.Build();

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
