using InstitutionService.Repositories;
using InstitutionService.Models;
using InstitutionService.DTOs;
using System.Globalization;

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
        var name = dto.Name.Trim();
        var normalizedName = name.ToUpper(
            CultureInfo.GetCultureInfo("tr-TR")
        );

        var nameExists = await _organizationTypeRepository.ExistsByNormalizedNameAsync(normalizedName);

        if (nameExists)
        {

            throw new InvalidOperationException(
                "Bu isimde bir kurum türü zaten mevcut"
            );

        }
        OrganizationType organizationType = new OrganizationType
        {
            Name = name,
            NormalizedName = normalizedName
        };

        await _organizationTypeRepository.AddAsync(organizationType);

        return organizationType;

    }




}
