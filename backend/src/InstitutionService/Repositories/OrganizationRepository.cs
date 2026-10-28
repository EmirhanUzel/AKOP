using InstitutionService.Data;
using Microsoft.EntityFrameworkCore;
using InstitutionService.Models;

namespace InstitutionService.Repositories;

public class OrganizationRepository : IOrganizationRepository
{
    private readonly InstitutionDbContext _institutionDbContext ;

    public OrganizationRepository (InstitutionDbContext institutionDbContext)
    {
        _institutionDbContext = institutionDbContext;
    }

    public async Task<List<Organization>> GetAllAsync()
    {
        return await _institutionDbContext.Organizations
            .AsNoTracking()
            .Include(organization => organization.OrganizationType)
            .ToListAsync();
    }

    public async Task<Organization?> GetByIdAsync(Guid id)
    {
        var result = await _institutionDbContext.Organizations
            .AsNoTracking()
            .Include(organization => organization.OrganizationType)
            .FirstOrDefaultAsync(organization => organization.Id == id);

        return result;
    }
    public async Task AddAsync(Organization organization)
    {
        await _institutionDbContext.Organizations.AddAsync(organization);
        await _institutionDbContext.SaveChangesAsync();
    }

    public async Task<bool> ExistsAsync(string normalizedName,int organizationTypeId,string city)
    {
        var result = await _institutionDbContext.Organizations
            .AnyAsync(organization =>
                organization.NormalizedName == normalizedName &&
                organization.OrganizationTypeId == organizationTypeId &&
                organization.City == city);

        return result;
    }




}
