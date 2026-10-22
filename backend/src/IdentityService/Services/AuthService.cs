using IdentityService.Models;
using Microsoft.AspNetCore.Identity;
using IdentityService.DTOs;
using IdentityService.Data;
using IdentityService.Constants;

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
        return token;

    }

    
}