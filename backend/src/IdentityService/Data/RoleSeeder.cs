using Microsoft.AspNetCore.Identity;
using IdentityService.Constants;

namespace IdentityService.Data;
public static class RoleSeeder
{
    public static async Task SeedRolesAsync(RoleManager<IdentityRole> roleManager){
        string[] roles = {
            RoleNames.Citizen,
            RoleNames.FieldStaff,
            RoleNames.OrgManager
        };

        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role)){
                var result = await roleManager.CreateAsync(new IdentityRole(role));
                
                if (!result.Succeeded){
                    throw new InvalidOperationException($"{role} Rol oluşturulamadı.");
                }
            }


        }

    }

}