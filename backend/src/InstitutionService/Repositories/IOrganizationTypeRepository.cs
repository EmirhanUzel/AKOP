using InstitutionService.Models;

namespace InstitutionService.Repositories;

public interface IOrganizationTypeRepository
{
    Task<List<OrganizationType>> GetAllAsync();
    Task<OrganizationType?> GetByIdAsync(int id);
    Task AddAsync(OrganizationType organizationType);
    Task<bool> ExistsByNormalizedNameAsync(string normalizedName);


}