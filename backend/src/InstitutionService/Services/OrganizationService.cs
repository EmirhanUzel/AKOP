using InstitutionService.Repositories;
using InstitutionService.DTOs;
using System.Globalization;
using InstitutionService.Models;

namespace InstitutionService.Services;

public class OrganizationService : IOrganizationService
{
    private readonly IOrganizationRepository _organizationRepository;
    private readonly IOrganizationTypeRepository _organizationTypeRepository;

    public OrganizationService(
        IOrganizationRepository organizationRepository,
        IOrganizationTypeRepository organizationTypeRepository)
    {
        _organizationRepository = organizationRepository;
        _organizationTypeRepository = organizationTypeRepository;
    }

    public async Task<List<OrganizationResponseDto>> GetAllAsync()
    {
        var organizations = await _organizationRepository.GetAllAsync();

        var responseDtos = new List<OrganizationResponseDto>();

        foreach (var organization in organizations)
        {
            var responseDto = new OrganizationResponseDto
            {
                Id = organization.Id,
                Name = organization.Name,
                OrganizationTypeId = organization.OrganizationTypeId,
                OrganizationTypeName = organization.OrganizationType.Name,
                City = organization.City,
                District = organization.District,
                ProfileInfo = organization.ProfileInfo,
                CreatedAt = organization.CreatedAt
            };

            responseDtos.Add(responseDto);
        }

        return responseDtos;
    }

    public async Task<OrganizationResponseDto?> GetByIdAsync(Guid id)
    {
        var organization = await _organizationRepository.GetByIdAsync(id);

        if (organization == null)
        {
            return null;
        }

        var responseDto = new OrganizationResponseDto
        {
                Id = organization.Id,
                Name = organization.Name,
                OrganizationTypeId = organization.OrganizationTypeId,
                OrganizationTypeName = organization.OrganizationType.Name,
                City = organization.City,
                District = organization.District,
                ProfileInfo = organization.ProfileInfo,
                CreatedAt = organization.CreatedAt
        };

        return responseDto;
    }

    public async Task<OrganizationResponseDto> CreateAsync(CreateOrganizationDto dto)
    {
        var culture = CultureInfo.GetCultureInfo("tr-TR");
        var name = dto.Name.Trim();
        var normalizedName = name.ToUpper(culture);
        var city = culture.TextInfo.ToTitleCase(dto.City.Trim().ToLower(culture));
        var district = string.IsNullOrWhiteSpace(dto.District)
            ? null
            : culture.TextInfo.ToTitleCase(dto.District.Trim().ToLower(culture));
        var profileInfo = string.IsNullOrWhiteSpace(dto.ProfileInfo)
            ? null
            : dto.ProfileInfo.Trim();

        var organizationType = await _organizationTypeRepository
            .GetByIdAsync(dto.OrganizationTypeId);

        if (organizationType == null)
        {
            throw new KeyNotFoundException("Kurum türü bulunamadı");
        }

        var exists = await _organizationRepository.ExistsAsync(
            normalizedName,
            dto.OrganizationTypeId,
            city);

        if (exists)
        {
            throw new InvalidOperationException("Bu isimde bir kurum zaten mevcut");
        }

        var newOrganization = new Organization
        {
            Name = name,
            NormalizedName = normalizedName,
            OrganizationTypeId = dto.OrganizationTypeId,
            City = city,
            District = district,
            ProfileInfo = profileInfo
        };

        await _organizationRepository.AddAsync(newOrganization);

        return new OrganizationResponseDto
        {
            Id = newOrganization.Id,
            Name = newOrganization.Name,
            OrganizationTypeId = newOrganization.OrganizationTypeId,
            OrganizationTypeName = organizationType.Name,
            City = newOrganization.City,
            District = newOrganization.District,
            ProfileInfo = newOrganization.ProfileInfo,
            CreatedAt = newOrganization.CreatedAt
        };
    }
}
