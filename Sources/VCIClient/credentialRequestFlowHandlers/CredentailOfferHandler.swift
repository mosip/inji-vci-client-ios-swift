public class CredentialOfferHandler {
    private let credentialOfferService: CredentialOfferService
    private let issuerMetadataService: IssuerMetadataService
    private let preAuthFlowService: PreAuthFlowService
    private let authorizationCodeFlowService: AuthorizationCodeFlowService

     init(
        credentialOfferService: CredentialOfferService = CredentialOfferService(),
        issuerMetadataService: IssuerMetadataService = IssuerMetadataService(),
        preAuthFlowService: PreAuthFlowService = PreAuthFlowService(),
        authorizationCodeFlowService: AuthorizationCodeFlowService = AuthorizationCodeFlowService()
    ) {
        self.credentialOfferService = credentialOfferService
        self.issuerMetadataService = issuerMetadataService
        self.preAuthFlowService = preAuthFlowService
        self.authorizationCodeFlowService = authorizationCodeFlowService
    }

    public func downloadCredentials(
        credentialOffer: String,
        clientMetadata: ClientMetaData,
        getTxCode: ((_ inputMode: String?, _ description: String?, _ length: Int?) async throws -> String)?,
        getProofJwt: @escaping (
            _ accessToken: String,
            _ cNonce: String?,
            _ issuerMetadata: [String: Any]?,
            _ credentialConfigurationId: String?
        ) async throws -> String,
        getAuthCode: @escaping (_ authorizationEndpoint: String) async throws -> String,
        onCheckIssuerTrust: ((_ issuerMetadata: [String: Any]) async throws -> Bool)? = nil,
        networkSession: NetworkManager = NetworkManager.shared,
        downloadTimeoutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis
    ) async throws -> CredentialResponse {
        let offer = try await credentialOfferService.fetchCredentialOffer(credentialOffer)

        let issuerMetadataResponse = try await issuerMetadataService.fetch(
            issuerUrl: offer.credentialIssuer,
            credentialConfigurationId: offer.credentialConfigurationIds.first ?? ""
        )

        try await ensureIssuerTrust(issuerMetadataResponse.raw as [String: Any], onCheck: onCheckIssuerTrust)

        if offer.isPreAuthorizedFlow {
            return try await preAuthFlowService.requestCredentials(
                issuerMetadataResult: issuerMetadataResponse,
                offer: offer,
                getTxCode: getTxCode,
                getProofJwt: getProofJwt,
                credentialConfigurationId: offer.credentialConfigurationIds.first!,
                downloadTimeoutInMillis: downloadTimeoutInMillis
            )
        } else if offer.isAuthorizationCodeFlow {
            return try await authorizationCodeFlowService.requestCredentials(
                issuerMetadataResult: issuerMetadataResponse,
                clientMetadata: clientMetadata,
                credentialOffer: offer,
                getAuthCode: getAuthCode,
                getProofJwt: getProofJwt,
                credentialConfigurationId: offer.credentialConfigurationIds.first,
                downloadTimeOutInMillis: downloadTimeoutInMillis
            )
        } else {
            throw OfferFetchFailedException("Credential offer does not contain a supported grant type")
        }
    }

    private func ensureIssuerTrust(
        _ rawMetadata: [String: Any],
        onCheck: ((_ issuerMetadata: [String: Any]) async throws -> Bool)?
    ) async throws {
        guard let onCheck = onCheck else { return }
        
        let consented = try await onCheck(rawMetadata)
        if !consented {
            throw OfferFetchFailedException("Issuer not trusted by user")
        }
    }
}
