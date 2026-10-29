namespace IdentityService.Clients;

public interface IOrganizationClient
{
    Task<bool> ExistsAsync(
        Guid institutionId,
        string authorizationHeader,
        CancellationToken cancellationToken = default
    );

    Task<bool> CurrentOrganizationExistsAsync(
        string authorizationHeader,
        CancellationToken cancellationToken = default
    );
}
