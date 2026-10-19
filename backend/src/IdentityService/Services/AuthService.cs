using IdentityService.Models;
using Microsoft.AspNetCore.Identity;
using IdentityService.DTOs;
using IdentityService.Data;

namespace IdentityService.Services;

public class AuthService
{
    private readonly UserManager<AppUser> _userManager;
    private readonly AppIdentityDbContext _dbContext;


    public AuthService(UserManager<AppUser> userManager,AppIdentityDbContext dbContext)
    {
        _userManager = userManager;
        _dbContext = dbContext;
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
            var roleResult = await _userManager.AddToRoleAsync(newUser,"Citizen");
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

}