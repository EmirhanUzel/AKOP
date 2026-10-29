using System.Net;

namespace IdentityService.Clients;

public class OrganizationClient : IOrganizationClient
{
    private readonly HttpClient _httpClient;

    public OrganizationClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public Task<bool> ExistsAsync(
        Guid institutionId,
        string authorizationHeader,
        CancellationToken cancellationToken = default)
    {
        return SendExistsRequestAsync(
            $"api/organizations/{institutionId}",
            authorizationHeader,
            cancellationToken
        );
    }

    public Task<bool> CurrentOrganizationExistsAsync(
        string authorizationHeader,
        CancellationToken cancellationToken = default)
    {
        return SendExistsRequestAsync(
            "api/organizations/me",
            authorizationHeader,
            cancellationToken
        );
    }

    private async Task<bool> SendExistsRequestAsync(
        string requestUri,
        string authorizationHeader,
        CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, requestUri);
        request.Headers.TryAddWithoutValidation(
            "Authorization",
            authorizationHeader
        );

        using var response = await _httpClient.SendAsync(
            request,
            cancellationToken
        );

        if (response.StatusCode == HttpStatusCode.NotFound)
        {
            return false;
        }

        response.EnsureSuccessStatusCode();
        return true;
    }
}
