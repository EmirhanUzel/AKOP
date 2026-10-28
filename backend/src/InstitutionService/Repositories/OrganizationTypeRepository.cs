using InstitutionService.Data;
using InstitutionService.Models;

using Microsoft.EntityFrameworkCore;
namespace InstitutionService.Repositories;

public class OrganizationTypeRepository : IOrganizationTypeRepository
{
    private readonly InstitutionDbContext _institutionDbContext ;

    public OrganizationTypeRepository (InstitutionDbContext institutionDbContext)
    {
        _institutionDbContext = institutionDbContext;
    }

    public async Task<List<OrganizationType>> GetAllAsync()
    {
        var results = await _institutionDbContext.OrganizationTypes.ToListAsync();

        return results;
    }

    public async Task<OrganizationType?> GetByIdAsync(int id)
    {
        var result = await _institutionDbContext.OrganizationTypes.FirstOrDefaultAsync(x => x.Id == id);
        return result;
    }

    public async Task AddAsync(OrganizationType organizationType)
    {
        await _institutionDbContext.OrganizationTypes.AddAsync(organizationType);
        await _institutionDbContext.SaveChangesAsync();
    }

    public async Task<bool> ExistsByNormalizedNameAsync(string normalizedName)
    {
        var result = await _institutionDbContext.OrganizationTypes
            .AnyAsync(organizationType =>
                organizationType.NormalizedName == normalizedName);

        return result;
    }


}