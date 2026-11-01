using Microsoft.AspNetCore.Identity;
using IdentityService.Models;
using IdentityService.DTOs;
using IdentityService.Data;
using IdentityService.Constants;
using Microsoft.EntityFrameworkCore;

namespace IdentityService.Services;

public class UserService
{
    private readonly UserManager<AppUser> _userManager;

    private readonly AppIdentityDbContext _dbContext;

    public UserService(UserManager<AppUser> userManager , AppIdentityDbContext dbContext)
    {
        _userManager = userManager;
        _dbContext = dbContext;
    }

    public async Task<MeResponseDto?> GetMyProfileAsync(string userId)
    {
        var user = await _userManager.FindByIdAsync(userId);
    
        if (user == null)
        {
            return null;
        }

        var roles = await _userManager.GetRolesAsync(user);

        if (roles.Count != 1)
        {
            return null;
        }

        var role = roles[0];
        
        var profileDto = new MeResponseDto{
            FirstName = user.FirstName,
            LastName = user.LastName,
            Email = user.Email ?? "",
            Role = role
        };
        return profileDto;

    }


    public async Task<IdentityResult> CreateInstitutionUserAsync(CreateInstitutionUserDto dto)
    {
        if (dto.Role != RoleNames.OrgManager && dto.Role != RoleNames.FieldStaff)
        {
            return IdentityResult.Failed(new IdentityError
            {
                Code = "InvalidInstitutionRole",
                Description = "Yalnızca OrgManager veya FieldStaff rolü atanabilir."
            });
        }
        if (dto.InstitutionId == Guid.Empty)
        {
            return IdentityResult.Failed( new IdentityError
            {
                Code = "InvalidInstitutionId",
                Description = "Geçerli bir kurum kimliği zorunludur."
            });
        }
        var email = dto.Email.Trim();
        var existingUser = await _userManager.FindByEmailAsync(email);
        if (existingUser != null)
        {
            return IdentityResult.Failed(new IdentityError
            {
                Code = "DuplicateEmail",
                Description = "Bu e-posta adresi zaten kayıtlı."
            });
        }

        await using var transaction = await _dbContext.Database
            .BeginTransactionAsync();

        var newUser = new AppUser
        {
            FirstName = dto.FirstName.Trim(),
            LastName = dto.LastName.Trim(),
            Email = email,
            UserName = email,
            InstitutionId = dto.InstitutionId
        };

        var result = await _userManager.CreateAsync(newUser, dto.Password);

        if (!result.Succeeded)
        {
            await transaction.RollbackAsync();
            return result;
        }

        var roleResult = await _userManager.AddToRoleAsync(newUser,dto.Role);
        if (!roleResult.Succeeded)
        {
            await transaction.RollbackAsync();
            return roleResult;
        }

        await transaction.CommitAsync();
        return result;
    }


    public async Task<IdentityResult> CreateFieldStaffAsync(CreateFieldStaffDto dto, Guid institutionId)
    {
        var institutionUserDto = new CreateInstitutionUserDto
        {
            Email = dto.Email,
            Password = dto.Password,
            FirstName = dto.FirstName,
            LastName = dto.LastName,
            InstitutionId = institutionId,
            Role = RoleNames.FieldStaff
        };

        return await CreateInstitutionUserAsync(institutionUserDto);
    }


    public async Task<IdentityResult> ChangePasswordAsync(string userId, ChangePasswordDto dto)
    {
        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
        {
            return IdentityResult.Failed(new IdentityError
            {
                Code = "UserNotFound",
                Description = "Kullanıcı bulunamadı."
            });
        }

        await using var transaction = await _dbContext.Database.BeginTransactionAsync();

        var result = await _userManager.ChangePasswordAsync(
            user,
            dto.CurrentPassword,
            dto.NewPassword
        );

        if (!result.Succeeded)
        {
            await transaction.RollbackAsync();
            return result;
        }

        var nowUtc = DateTime.UtcNow;

        await _dbContext.RefreshTokens
            .Where(refreshToken =>
                refreshToken.UserId == user.Id &&
                refreshToken.RevokedAtUtc == null &&
                refreshToken.ExpiresAtUtc > nowUtc)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(
                    refreshToken => refreshToken.RevokedAtUtc,
                    (DateTime?)nowUtc
                ));

        await transaction.CommitAsync();
        return result;
    }
}
