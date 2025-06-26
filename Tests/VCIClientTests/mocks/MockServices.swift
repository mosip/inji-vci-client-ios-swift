
import Foundation
@testable import VCIClient

// MARK: - Mock AuthServerResolver

final class MockAuthServerResolver: AuthServerResolver {
    var mockTokenEndpoint: String? = "https://example.com/token"
    var mcokAuthorizationEndpoint: String? = "https://example.com/auth"
    override func resolveForPreAuth(issuerMetadata: IssuerMetadata, credentialOffer: CredentialOffer) async throws -> AuthServerMetadata {
        return AuthServerMetadata(
            issuer: "mock-issuer",
            grantTypesSupported: nil,
            tokenEndpoint: mockTokenEndpoint,
            authorizationEndpoint: nil
        )
    }

    override func resolveForAuthCode(issuerMetadata: IssuerMetadata) async throws -> AuthServerMetadata {
        return AuthServerMetadata(
            issuer: "mock-issuer",
            grantTypesSupported: nil,
            tokenEndpoint: mockTokenEndpoint,
            authorizationEndpoint: mcokAuthorizationEndpoint
        )
    }
}

// MARK: - Mock TokenService

final class MockTokenService: TokenService {
    override func getAccessToken(tokenEndpoint: String,
                                 timeoutMillis: Int64 = Constants.defaultNetworkTimeoutInMillis,
                                 preAuthCode: String,
                                 txCode: String? = nil) async throws -> TokenResponse {
        return TokenResponse(
            accessToken: "mock-access-token",
            tokenType: "Bearer",
            expiresIn: 3600,
            cNonce: "mock-cnonce",
            cNonceExpiresIn: 600
        )
    }

    override func getAccessToken(tokenEndpoint: String, timeoutMillis: Int64 = Constants.defaultNetworkTimeoutInMillis, authCode: String, clientId: String? = nil, redirectUri: String? = nil, codeVerifier: String? = nil) async throws -> TokenResponse {
        return TokenResponse(
            accessToken: "mock-access-token",
            tokenType: "Bearer",
            expiresIn: 3600,
            cNonce: "mock-cnonce",
            cNonceExpiresIn: 600
        )
    }
}

// MARK: - Mock CredentialRequestExecutor

final class MockCredentialRequestExecutor: CredentialRequestExecutor {
    var shouldReturnNil = false

    init(shouldReturnNil: Bool = false) {
        self.shouldReturnNil = shouldReturnNil
    }

    override func requestCredential(
        issuerMetadata: IssuerMetadata,
        proof: Proof,
        accessToken: String,
        timeoutInMillis: Int64 = 10000,
        session: NetworkManager = NetworkManager.shared
    ) async throws -> CredentialResponse? {
        if shouldReturnNil { return nil }

        return CredentialResponse(credential: AnyCodable("mock-credential"))
    }
}

final class MockCredentialOfferHandler: CredentialOfferHandler {
    var shouldThrow = false
    var didCallDownload = false

    override func downloadCredentials(
        credentialOffer: String,
        clientMetadata: ClientMetaData,
        getTxCode: ((_ inputMode: String?, _ description: String?, _ _length: Int?) async throws -> String)? = nil,
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
        didCallDownload = true
        if shouldThrow {
            throw DownloadFailedException("Simulated failure")
        }
        return CredentialResponse.mock()
    }
}

class MockTrustedIssuerHandler: TrustedIssuerHandler {
    var shouldThrow = false
    var didCallDownload = false

    override func downloadCredentials(
        issuerMetadata: IssuerMetadata,
        clientMetadata: ClientMetaData,
        getAuthCode: @escaping (_ authorizationEndpoint: String) async throws -> String,
        getProofJwt: @escaping (
            _ accessToken: String,
            _ cNonce: String?,
            _ issuerMetadata: [String: Any]?,
            _ credentialConfigurationId: String?
        ) async throws -> String,
        downloadTimeoutInMillis timeoutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis,
        networkSession: NetworkManager = NetworkManager.shared
    ) async throws -> CredentialResponse? {
        didCallDownload = true
        if shouldThrow {
            throw DownloadFailedException("Simulated failure")
        }
        return CredentialResponse.mock()
    }
}

final class MockNetworkManager: NetworkManager {
    var responseBody: String = ""
    var shouldThrowNetworkError: Bool = false
    var simulateDelay: TimeInterval = 0
    var capturedParams: [String: String] = [:]

    override func sendRequest(
        url: String,
        method: HttpMethod,
        headers: [String: String]?,
        bodyParams: [String: String]?,
        timeoutMillis: Int64
    ) async throws -> NetworkResponse {
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1000000000))
        }

        if shouldThrowNetworkError {
            throw DownloadFailedException("Simulated network failure")
        }

        capturedParams = bodyParams ?? [:]
        return NetworkResponse(body: responseBody, headers: nil)
    }
}

final class MockAuthServerDiscoveryService: AuthServerDiscoveryService {
    var mockMetadataByUrl: [String: AuthServerMetadata] = [:]
    var urlsThatThrow: Set<String> = []

    override func discover(baseUrl: String) async throws -> AuthServerMetadata {
        if urlsThatThrow.contains(baseUrl) {
            throw AuthServerDiscoveryException("Simulated failure for \(baseUrl)")
        }
        guard let metadata = mockMetadataByUrl[baseUrl] else {
            throw AuthServerDiscoveryException("No mock available for \(baseUrl)")
        }
        return metadata
    }
}

// MARK: - PKCESession Service

final class MockPKCESessionManager: PKCESessionManager {
    override func createSession() -> PKCESession {
        let codeVerifier = "mock-code"
        let codeChallenge = "mock-challenge"
        let state = "mock-state"
        let nonce = "mock-nonce"
        return PKCESession(
            codeVerifier: codeVerifier,
            codeChallenge: codeChallenge,
            state: state,
            nonce: nonce
        )
    }
}
