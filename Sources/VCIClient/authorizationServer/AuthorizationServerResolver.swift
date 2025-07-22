import Foundation

class AuthorizationServerResolver {
    let authServerDiscoveryService: AuthorizationServerDiscoveryService
    init(authServerDiscoveryService: AuthorizationServerDiscoveryService? = nil) {
        self.authServerDiscoveryService = authServerDiscoveryService ?? AuthorizationServerDiscoveryService()
    }

    func resolveForPreAuth(
        issuerMetadata: IssuerMetadata,
        credentialOffer: CredentialOffer
    ) async throws -> AuthorizationServerMetadata {
        let offerAuthServer = credentialOffer.grants?.preAuthorizedGrant?.authorizationServer
        return try await resolveAuthServer(
            offerGrantAuthServer: offerAuthServer,
            issuerMetadata: issuerMetadata,
            expectedGrantType: GrantType.preAuthorized.rawValue,
            credentialIssuer: issuerMetadata.credentialIssuer
        )
    }
    
    func resolveForAuthCode(
        issuerMetadata: IssuerMetadata,
        credentialOffer: CredentialOffer? = nil
    ) async throws -> AuthorizationServerMetadata {
        let offerAuthServer = credentialOffer?.grants?.authorizationCodeGrant?.authorizationServer
        return try await resolveAuthServer(
            offerGrantAuthServer: offerAuthServer,
            issuerMetadata: issuerMetadata,
            expectedGrantType: GrantType.authorizationCode.rawValue,
            credentialIssuer: issuerMetadata.credentialIssuer
        )
    }


    private func resolveAuthServer(
        offerGrantAuthServer: String?,
        issuerMetadata: IssuerMetadata,
        expectedGrantType: String,
        credentialIssuer: String
    ) async throws -> AuthorizationServerMetadata {
        let authServers = issuerMetadata.authorizationServers

        if let servers = authServers, servers.count == 1 {
            return try await discoverAndValidate(
                authServerUrl: servers[0],
                expectedGrantType: expectedGrantType
            )
        }

        if let grantServer = offerGrantAuthServer, !grantServer.isEmpty {
            return try await discoverAndValidate(
                authServerUrl: grantServer,
                expectedGrantType: expectedGrantType
            )
        }

        if let servers = authServers, !servers.isEmpty {
            return try await resolveFirstValid(
                authServers: servers,
                expectedGrantType: expectedGrantType
            )
        }

        return try await discoverAndValidate(
            authServerUrl: credentialIssuer,
            expectedGrantType: expectedGrantType
        )
    }

    private func discoverAndValidate(
        authServerUrl: String,
        expectedGrantType: String
    ) async throws -> AuthorizationServerMetadata {
        let authServerMetadata = try await authServerDiscoveryService.discover(baseUrl: authServerUrl)

        if authServerMetadata.issuer != authServerUrl {
            throw AutorizationServerDiscoveryException(
                "Issuer mismatch: expected '\(authServerUrl)', got '\(authServerMetadata.issuer)'"
            )
        }

        let supportedGrants = authServerMetadata.grantTypesSupported ??
            [GrantType.authorizationCode.rawValue, GrantType.implicit.rawValue]

        if !supportedGrants.contains(expectedGrantType),
           expectedGrantType != GrantType.preAuthorized.rawValue {
            throw AutorizationServerDiscoveryException(
                "Grant type '\(expectedGrantType)' not supported by auth server."
            )
        }

        if expectedGrantType == GrantType.authorizationCode.rawValue,
           authServerMetadata.authorizationEndpoint?.isEmpty ?? true {
            throw AutorizationServerDiscoveryException(
                "Missing authorization_endpoint for authorization_code flow."
            )
        }

        return authServerMetadata
    }

    private func resolveFirstValid(
        authServers: [String],
        expectedGrantType: String
    ) async throws -> AuthorizationServerMetadata {
        try await withThrowingTaskGroup(of: AuthorizationServerMetadata?.self) { group in
            for url in authServers {
                group.addTask {
                    try? await self.discoverAndValidate(authServerUrl: url, expectedGrantType: expectedGrantType)
                }
            }

            for try await result in group {
                if let metadata = result {
                    group.cancelAll()
                    return metadata
                }
            }

            throw AutorizationServerDiscoveryException(
                "None of the authorization servers responded with valid metadata."
            )
        }
    }
}
