using InstitutionService.DTOs;



namespace InstitutionService.Services;

public interface IOrganizationService
{
    Task<List<OrganizationResponseDto>> GetAllAsync();

    Task<OrganizationResponseDto?> GetByIdAsync(Guid id);

    Task<OrganizationResponseDto> CreateAsync(CreateOrganizationDto dto);

}