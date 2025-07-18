class TrustedIssuerFlowHandler {
    private let authorizationCodeFlowService: AuthorizationCodeFlowService
    private let issuerMetadataService: IssuerMetadataService

    init(authService: AuthorizationCodeFlowService = AuthorizationCodeFlowService(), issuerMetadataService: IssuerMetadataService = IssuerMetadataService()) {
        authorizationCodeFlowService = authService
        self.issuerMetadataService = issuerMetadataService
    }

    public func downloadCredentials(
        credentialIssuer: String,
        credentialConfigurationId: String,
        clientMetadata: ClientMetadata,
        authorizeUser: @escaping AuthorizeUserCallback,
        getTokenResponse: @escaping TokenresponseCallback,
        getProofJwt: @escaping ProofJwtCallback,
        downloadTimeoutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis,
        networkSession: NetworkManager = NetworkManager.shared
    ) async throws -> CredentialResponse? {
        let issuerMetadata = try await issuerMetadataService
            .fetchIssuerMetadataResult(
                credentialIssuer: credentialIssuer,
                credentialConfigurationId: credentialConfigurationId
            )
        let proofSigningAlgorithmsSupportedSupported = issuerMetadata.extractJwtProofSigningAlgorithms(credentialConfigurationId: credentialConfigurationId)

        return try await authorizationCodeFlowService.requestCredentials(
            issuerMetadata: issuerMetadata.issuerMetadata,
            clientMetadata: clientMetadata,
            authorizeUser: authorizeUser,
            getTokenResponse: getTokenResponse,
            getProofJwt: getProofJwt,
            credentialConfigurationId: credentialConfigurationId,
            proofSigningAlgorithmsSupportedSupported: proofSigningAlgorithmsSupportedSupported,
            downloadTimeOutInMillis: downloadTimeoutInMillis,
            session: networkSession
        )
    }
}
