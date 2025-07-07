import Foundation

 class PreAuthFlowService {
    private let authServerResolver: AuthServerResolver
    private let tokenService: TokenService
    private let credentialExecutor: CredentialRequestExecutor

    init(
        authServerResolver: AuthServerResolver = AuthServerResolver(),
        tokenService: TokenService = TokenService(),
        credentialExecutor: CredentialRequestExecutor = CredentialRequestExecutor()
    ) {
        self.authServerResolver = authServerResolver
        self.tokenService = tokenService
        self.credentialExecutor = credentialExecutor
    }

    func requestCredentials(
        issuerMetadataResult: IssuerMetadataResult,
        offer: CredentialOffer,
        getTxCode: ((_ inputMode: String?, _ description: String?, _ _length: Int?) async throws -> String)? = nil,
        getProofJwt: @escaping (
            _ accessToken: String,
            _ cNonce: String?,
            _ issuerMetadata: [String: Any],
            _ credentialConfigurationId: String
        ) async throws -> String,
        credentialConfigurationId: String,
        downloadTimeoutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis
    ) async throws -> CredentialResponse {
        let authServerMetadata = try await authServerResolver
            .resolveForPreAuth(issuerMetadata: issuerMetadataResult.issuerMetadata, credentialOffer: offer)

        guard let tokenEndpoint = authServerMetadata.tokenEndpoint else {
            throw DownloadFailedException("Token endpoint is missing in AuthServer metadata.")
        }

        let txCode: String? = await {
            if offer.grants?.preAuthorizedGrant?.txCode != nil {
                let txCode = offer.grants?.preAuthorizedGrant?.txCode
                return try? await getTxCode?(txCode?.inputMode, txCode?.description, txCode?.length)
            } else {
                return nil
            }
        }()

        if offer.grants?.preAuthorizedGrant?.txCode != nil && txCode == nil {
            throw DownloadFailedException("tx_code required but no provider was given.")
        }

        guard let grant = offer.grants?.preAuthorizedGrant else {
            throw InvalidDataProvidedException("Missing pre-authorized grant details.")
        }

        let token = try await tokenService.getAccessToken(
            tokenEndpoint: tokenEndpoint,
            preAuthCode: grant.preAuthorizedCode,
            txCode: txCode
        )

        let jwt = try await getProofJwt(
            token.accessToken,
            token.cNonce,
            issuerMetadataResult.raw as [String : Any],
            credentialConfigurationId
        )

        let proof = JWTProof(jwt: jwt)

        guard let credential = try await credentialExecutor.requestCredential(
            issuerMetadata: issuerMetadataResult.issuerMetadata,
            proof: proof,
            accessToken: token.accessToken,
            timeoutInMillis: downloadTimeoutInMillis
        ) else {
            throw DownloadFailedException("Credential request failed.")
        }

        return credential
    }
}
