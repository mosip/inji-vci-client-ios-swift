public class TrustedIssuerHandler {
    private let authService: AuthorizationCodeFlowService

    init(authService: AuthorizationCodeFlowService = AuthorizationCodeFlowService()) {
        self.authService = authService
    }

    public func downloadCredentials(
        issuerMetadata: IssuerMetadata,
        clientMetadata: ClientMetaData,
        getAuthCode: @escaping (_ authorizationEndpoint: String) async throws -> String,
        getProofJwt: @escaping (
            _ accessToken: String,
            _ cNonce: String?,
            _ issuerMetadata: [String: Any]?,
            _ credentialConfigurationId: String?
        ) async throws -> String,
        downloadTimeoutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis,
        networkSession: NetworkManager = NetworkManager.shared
    ) async throws -> CredentialResponse? {
        return try await authService.requestCredentials(
            issuerMetadataResult: IssuerMetadataResult(issuerMetadata: issuerMetadata, raw: [:]),
            clientMetadata: clientMetadata,
            getAuthCode: getAuthCode,
            getProofJwt: getProofJwt,
            downloadTimeOutInMillis: downloadTimeoutInMillis,
            session: networkSession
        )
    }
}
