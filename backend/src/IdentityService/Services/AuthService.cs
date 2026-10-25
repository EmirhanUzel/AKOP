using IdentityService.Models;
using Microsoft.AspNetCore.Identity;
using IdentityService.DTOs;
using IdentityService.Data;
using IdentityService.Constants;
using Microsoft.EntityFrameworkCore;

namespace IdentityService.Services;

public class AuthService
{
    private readonly UserManager<AppUser> _userManager;
    private readonly AppIdentityDbContext _dbContext;

    private readonly TokenService _tokenService;


    public AuthService(UserManager<AppUser> userManager,AppIdentityDbContext dbContext, TokenService tokenService)
    {
        _userManager = userManager;
        _dbContext = dbContext;
        _tokenService = tokenService;
    }

    public async Task<IdentityResult> RegisterAsync(RegisterDto dto)
    {
        var existingUser = await _userManager.FindByEmailAsync(dto.Email);

        if (existingUser != null)
        {
            return IdentityResult.Failed(new IdentityError
            {
                Code = "DuplicateEmail",
                Description = "Bu e-posta adresi zaten kayıtlı."
            });
        }
        
        await using var transaction = await _dbContext.Database.BeginTransactionAsync();        
        
        var newUser = new AppUser
        {
            FirstName = dto.FirstName,
            LastName = dto.LastName,
            Email = dto.Email,
            UserName = dto.Email
        };
        
        var result = await _userManager.CreateAsync(newUser,dto.Password);
        
        if (result.Succeeded)
        {
            var roleResult = await _userManager.AddToRoleAsync(newUser,RoleNames.Citizen);
            if (roleResult.Succeeded)
            {
                await transaction.CommitAsync();
                return result;
            }
            else
            {
                await transaction.RollbackAsync();
                return roleResult;     
            }
        }
        else
        {
            await transaction.RollbackAsync();
            return result;
        }

        

    }


    public async Task<AuthResponseDto?> LoginAsync(LoginDto dto)
    {
        var existingUser = await _userManager.FindByEmailAsync(dto.Email);

        if (existingUser == null)
        {
            return null;
        }
        var isPasswordValid = await _userManager.CheckPasswordAsync(
            existingUser,
            dto.Password
        );

        if (!isPasswordValid)

        {
            return null;
        }
        
        var roles = await _userManager.GetRolesAsync(existingUser);

        if (roles.Count != 1)
        {
            return null;
        }

        var role = roles[0];
        var token = _tokenService.GenerateToken(existingUser,role);
        
        var refreshTokenValue = _tokenService.GenerateRefreshToken();

        var refreshTokenHash = _tokenService.HashRefreshToken(refreshTokenValue);

        var refreshTokenRecord = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = existingUser.Id,
            TokenHash = refreshTokenHash,
            CreatedAtUtc = DateTime.UtcNow,
            ExpiresAtUtc = DateTime.UtcNow.AddDays(7),
            RevokedAtUtc = null
        };

        _dbContext.RefreshTokens.Add(refreshTokenRecord);

        await _dbContext.SaveChangesAsync();
        
        token.RefreshToken = refreshTokenValue;

        return token;

    }

    
    public async Task<AuthResponseDto?> RefreshAsync(RefreshTokenRequestDto dto)
    {
        // 1. Gelen token boş mu?
        if (string.IsNullOrWhiteSpace(dto.RefreshToken))
        {
            return null;
        }

        // 2. Gelen Refresh Token'ın hash değerini hesapla
        var tokenHash = _tokenService.HashRefreshToken(dto.RefreshToken);

        // 3. PostgreSQL'de token kaydını bul
        var tokenRecord = await _dbContext.RefreshTokens
            .AsNoTracking()
            .FirstOrDefaultAsync(rt => rt.TokenHash == tokenHash);

        if (tokenRecord == null)
        {
            return null;
        }

        // 4. Token daha önce iptal edilmiş mi veya süresi dolmuş mu?
        if (tokenRecord.RevokedAtUtc != null ||
            tokenRecord.ExpiresAtUtc <= DateTime.UtcNow)
        {
            return null;
        }

        // 5. Token'ın ait olduğu kullanıcıyı bul
        var user = await _userManager.FindByIdAsync(tokenRecord.UserId);

        if (user == null)
        {
            return null;
        }

        // 6. Kullanıcının rolünü öğren
        var roles = await _userManager.GetRolesAsync(user);

        if (roles.Count != 1)
        {
            return null;
        }

        var role = roles[0];

        // 7. Yeni Access Token oluştur
        var newAccessToken = _tokenService.GenerateToken(user, role);

        // 8. Yeni Refresh Token oluştur ve hash'le
        var newRefreshToken = _tokenService.GenerateRefreshToken();
        var newRefreshTokenHash = _tokenService.HashRefreshToken(newRefreshToken);

        var nowUtc = DateTime.UtcNow;

        // 9. Eski token'ı iptal etme ve yenisini kaydetme
        // işlemlerini aynı transaction içerisinde gerçekleştir
        await using var transaction = await _dbContext.Database.BeginTransactionAsync();

        var updatedRows = await _dbContext.RefreshTokens
            .Where(rt =>
                rt.Id == tokenRecord.Id &&
                rt.RevokedAtUtc == null &&
                rt.ExpiresAtUtc > nowUtc)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(rt => rt.RevokedAtUtc, (DateTime?)nowUtc));

        // Token başka bir istekte zaten kullanılmışsa reddet
        if (updatedRows != 1)
        {
            await transaction.RollbackAsync();
            return null;
        }

        // 10. Yeni Refresh Token kaydını oluştur
        var newRefreshTokenRecord = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = newRefreshTokenHash,
            CreatedAtUtc = nowUtc,
            ExpiresAtUtc = nowUtc.AddDays(7),
            RevokedAtUtc = null
        };

        _dbContext.RefreshTokens.Add(newRefreshTokenRecord);

        await _dbContext.SaveChangesAsync();

        // 11. Değişiklikleri kalıcı olarak kaydet
        await transaction.CommitAsync();

        // 12. Gerçek Refresh Token'ı kullanıcıya gönder
        newAccessToken.RefreshToken = newRefreshToken;

        return newAccessToken;
    }


    public async Task LogoutAsync(RefreshTokenRequestDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.RefreshToken))
        {
            return;
        }
        var tokenHash = _tokenService.HashRefreshToken(dto.RefreshToken);

        await _dbContext.RefreshTokens
            .Where(rt =>
                rt.TokenHash == tokenHash &&
                rt.RevokedAtUtc == null)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(rt => rt.RevokedAtUtc, (DateTime?)DateTime.UtcNow));

    }
}