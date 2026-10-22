using IdentityService.Models;
using IdentityService.DTOs;

using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;
using System.Text;

using Microsoft.IdentityModel.Tokens;

namespace IdentityService.Services;

public class TokenService
{
    private readonly IConfiguration _configuration;

    public TokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public AuthResponseDto GenerateToken(AppUser user, string role)
    {
        // 1. JWT yapılandırma bilgilerini oku
        var key = _configuration["Jwt:Key"]
            ?? throw new InvalidOperationException("JWT anahtarı bulunamadı.");

        var issuer = _configuration["Jwt:Issuer"]
            ?? throw new InvalidOperationException("JWT Issuer bulunamadı.");

        var audience = _configuration["Jwt:Audience"]
            ?? throw new InvalidOperationException("JWT Audience bulunamadı.");


        // 2. Kullanıcı bilgilerini Claims listesine ekle
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id),

            new Claim(
                ClaimTypes.Email,
                user.Email ?? throw new InvalidOperationException(
                    "Kullanıcının e-posta adresi bulunamadı."
                )
            ),

            new Claim(ClaimTypes.Role, role)
        };


        // 3. Kullanıcı bir kuruma bağlıysa kurum bilgisini ekle
        if (user.InstitutionId.HasValue)
        {
            claims.Add(
                new Claim(
                    "institutionId",
                    user.InstitutionId.Value.ToString()
                )
            );
        }


        // 4. Gizli anahtarı JWT imzalama için hazırla
        var securityKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(key)
        );


        // 5. İmzalama bilgilerini oluştur
        var credentials = new SigningCredentials(
            securityKey,
            SecurityAlgorithms.HmacSha256
        );


        // 6. Token'ın geçerlilik süresini belirle
        var expiresAtUtc = DateTime.UtcNow.AddMinutes(30);


        // 7. JWT oluştur
        var jwtToken = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: expiresAtUtc,
            signingCredentials: credentials
        );


        // 8. JWT'yi string formatına dönüştür
        var tokenHandler = new JwtSecurityTokenHandler();

        var accessToken = tokenHandler.WriteToken(jwtToken);


        // 9. Giriş yanıtını oluştur
        return new AuthResponseDto
        {
            AccessToken = accessToken,
            Role = role,
            ExpiresAtUtc = expiresAtUtc
        };
    }
}