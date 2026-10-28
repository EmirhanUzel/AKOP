using InstitutionService.Models;

namespace InstitutionService.Repositories;

public interface IOrganizationRepository
{
    Task<List<Organization>> GetAllAsync();

    Task<Organization?> GetByIdAsync(Guid id);

    Task AddAsync(Organization organization);

    Task<bool> ExistsAsync(
        string normalizedName,
        int organizationTypeId,
        string city
    );
}