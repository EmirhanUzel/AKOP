using InstitutionService.Models;
using InstitutionService.DTOs;

namespace InstitutionService.Services;

public interface IOrganizationTypeService
{
    Task<List<OrganizationType>> GetAllAsync();
    Task<OrganizationType?> GetByIdAsync(int id);
    Task<OrganizationType> CreateAsync(CreateOrganizationTypeDto dto);


}