import Foundation

class AuthorizationCodeFlowService {
    private let authServerResolver: AuthorizationServerResolver
    private let tokenService: TokenService
    private let credentialRequestExecutor: CredentialRequestExecutor
    private let pkceSessionManager: PKCESessionManager

    init(
        authServerResolver: AuthorizationServerResolver = AuthorizationServerResolver(),
        tokenService: TokenService = TokenService(),
        credentialExecutor: CredentialRequestExecutor = CredentialRequestExecutor(),
        pkceSessionManager: PKCESessionManager = PKCESessionManager()
    ) {
        self.authServerResolver = authServerResolver
        self.tokenService = tokenService
        self.credentialRequestExecutor = credentialExecutor
        self.pkceSessionManager = pkceSessionManager
    }

    func requestCredentials(
        issuerMetadata: IssuerMetadata,
        clientMetadata: ClientMetadata,
        authorizeUser: @escaping AuthorizeUserCallback,
        getTokenResponse: @escaping TokenResponseCallback,
        getProofJwt: @escaping ProofJwtCallback,
        credentialConfigurationId: String,
        proofSigningAlgorithmsSupportedSupported: [String],
        credentialOffer: CredentialOffer? = nil,
        downloadTimeOutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis,
        session: NetworkManager = NetworkManager.shared
    ) async throws -> CredentialResponse {
        do {
            let pkceSession = pkceSessionManager.createSession()

            let authServerMetadata = try await authServerResolver.resolveForAuthCode(issuerMetadata: issuerMetadata, credentialOffer: credentialOffer)

            let token = try await performAuthorizationAndGetToken(
                authServerMetadata: authServerMetadata,
                issuerMetadata: issuerMetadata,
                clientMetadata: clientMetadata,
                authorizeUser: authorizeUser,
                pkceSession: pkceSession,
                getTokenResponse: getTokenResponse
            )

            let jwt = try await getProofJwt(
                issuerMetadata.credentialIssuer,
                token.cNonce,
                proofSigningAlgorithmsSupportedSupported
            )

            let proof = JWTProof(jwt: jwt)

            guard let response = try await credentialRequestExecutor.requestCredential(
                issuerMetadata: issuerMetadata, credentialConfigurationId: credentialConfigurationId,
                proof: proof,
                accessToken: token.accessToken,
                timeoutInMillis: downloadTimeOutInMillis,
                session: session
            ) else {
                throw DownloadFailedException("Credential request returned nil.")
            }

            return response

        } catch {
            throw DownloadFailedException("Download failed via authorization code flow: \(error.localizedDescription)")
        }
    }

    private func performAuthorizationAndGetToken(
        authServerMetadata: AuthorizationServerMetadata,
        issuerMetadata: IssuerMetadata,
        clientMetadata: ClientMetadata,
        authorizeUser: @escaping AuthorizeUserCallback,
        pkceSession: PKCESessionManager.PKCESession,
        getTokenResponse: @escaping TokenResponseCallback
    ) async throws -> TokenResponse {
        guard let authorizationEndpoint = authServerMetadata.authorizationEndpoint else {
            throw DownloadFailedException("Missing authorization endpoint")
        }

        guard let tokenEndpoint = issuerMetadata.tokenEndpoint ?? authServerMetadata.tokenEndpoint else {
            throw DownloadFailedException("Missing token endpoint")
        }

        let authUrl = AuthorizationUrlBuilder.build(
            baseUrl: authorizationEndpoint,
            clientId: clientMetadata.clientId,
            redirectUri: clientMetadata.redirectUri,
            scope: issuerMetadata.scope!,
            state: pkceSession.state,
            codeChallenge: pkceSession.codeChallenge,
            nonce: pkceSession.nonce
        )

        let authCode = try await authorizeUser(authUrl)

        return try await tokenService.getAccessToken(
            getTokenResponse: getTokenResponse,
            tokenEndpoint: tokenEndpoint,
            authCode: authCode,
            clientId: clientMetadata.clientId,
            redirectUri: clientMetadata.redirectUri,
            codeVerifier: pkceSession.codeVerifier
        )
    }
}
