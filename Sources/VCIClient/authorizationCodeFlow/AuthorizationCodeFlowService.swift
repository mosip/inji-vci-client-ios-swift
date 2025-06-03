import Foundation

final class AuthorizationCodeFlowService {
    private let authServerResolver: AuthServerResolver
    private let tokenService: TokenService
    private let credentialExecutor: CredentialRequestExecutor
    private let pkceSessionManager: PKCESessionManager

    init(
        authServerResolver: AuthServerResolver = AuthServerResolver(),
        tokenService: TokenService = TokenService(),
        credentialExecutor: CredentialRequestExecutor = CredentialRequestExecutor(),
        pkceSessionManager: PKCESessionManager = PKCESessionManager()
    ) {
        self.authServerResolver = authServerResolver
        self.tokenService = tokenService
        self.credentialExecutor = credentialExecutor
        self.pkceSessionManager = pkceSessionManager
    }

    func requestCredentials(
        issuerMetadataResult: IssuerMetadataResult,
        clientMetadata: ClientMetaData,
        credentialOffer: CredentialOffer? = nil,
        getAuthCode: @escaping (_ authorizationEndpoint: String) async throws -> String,
        getProofJwt: @escaping (
            _ accessToken: String,
            _ cNonce: String?,
            _ issuerMetadata: [String: Any]?,
            _ credentialConfigurationId: String?
        ) async throws -> String,
        credentialConfigurationId: String? = nil,
        downloadTimeOutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis,
        session: NetworkManager = NetworkManager.shared
    ) async throws -> CredentialResponse {
        do {
            let pkceSession = pkceSessionManager.createSession()

            let authServerMetadata = try await {
                if let offer = credentialOffer {
                    return try await authServerResolver.resolveForAuthCode(issuerMetadata: issuerMetadataResult.issuerMetadata, credentialOffer: offer)
                } else {
                    return try await authServerResolver.resolveForAuthCode(issuerMetadata: issuerMetadataResult.issuerMetadata)
                }
            }()

            let token = try await performAuthorizationAndGetToken(
                authServerMetadata: authServerMetadata,
                issuerMetadata: issuerMetadataResult.issuerMetadata,
                clientMetadata: clientMetadata,
                getAuthCode: getAuthCode,
                pkceSession: pkceSession
            )

            let jwt = try await getProofJwt(
                token.accessToken,
                token.cNonce,
                issuerMetadataResult.raw as [String : Any],
                credentialConfigurationId
            )

            let proof = JWTProof(jwt: jwt)

            guard let response = try await credentialExecutor.requestCredential(
                issuerMetadata: issuerMetadataResult.issuerMetadata,
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
        authServerMetadata: AuthServerMetadata,
        issuerMetadata: IssuerMetadata,
        clientMetadata: ClientMetaData,
        getAuthCode: @escaping (_ authorizationEndpoint: String) async throws -> String,
        pkceSession: PKCESessionManager.PKCESession
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

        let authCode = try await getAuthCode(authUrl)

        return try await tokenService.getAccessToken(
            tokenEndpoint: tokenEndpoint,
            authCode: authCode,
            clientId: clientMetadata.clientId,
            redirectUri: clientMetadata.redirectUri,
            codeVerifier: pkceSession.codeVerifier
        )
    }
}
