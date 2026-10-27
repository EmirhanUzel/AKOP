using InstitutionService.Repositories;
using InstitutionService.Models;
using InstitutionService.DTOs;

namespace InstitutionService.Services;

public class OrganizationTypeService : IOrganizationTypeService
{
    private readonly IOrganizationTypeRepository _organizationTypeRepository;
    public OrganizationTypeService(IOrganizationTypeRepository organizationTypeRepository)
    {
        _organizationTypeRepository = organizationTypeRepository;
    }

    public async Task<List<OrganizationType>> GetAllAsync()
    {
        var results = await _organizationTypeRepository.GetAllAsync();
        return results;
    }

    public async Task<OrganizationType?> GetByIdAsync(int id)
    {
        var result = await _organizationTypeRepository.GetByIdAsync(id);
        return result;
    }

    public async Task<OrganizationType> CreateAsync(CreateOrganizationTypeDto dto)
    {
        OrganizationType organizationType = new OrganizationType
        {
            Name = dto.Name
        };

        await _organizationTypeRepository.AddAsync(organizationType);

        return organizationType;
    }




}