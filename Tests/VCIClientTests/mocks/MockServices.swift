
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
    var responseHeaders: [AnyHashable: Any]? = nil
    var shouldThrowTimeout: Bool = false
    var capturedUrlRequest: URLRequest?
    
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
    
    override func sendRequest(request: URLRequest) async throws -> NetworkResponse {
        if simulateDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulateDelay * 1_000_000_000))
        }

        if shouldThrowTimeout {
            throw NetworkRequestTimeoutException("Simulated timeout")
        }
        if shouldThrowNetworkError {
            throw DownloadFailedException("Simulated network failure")
        }

        capturedUrlRequest = request

        return NetworkResponse(
            body: responseBody,
            headers: responseHeaders
        )
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

class MockValidCredentialRequest: CredentialRequestProtocol {
    required init(accessToken: String, issuerMetaData: IssuerMetadata, proof: JWTProof) {
    }

    func validateIssuerMetadata() -> ValidatorResult {
        return ValidatorResult(isValid: true)
    }

    func constructRequest() throws -> URLRequest {
        return URLRequest(url: URL(string: "https://example.com")!)
    }
}

class MockInvalidCredentialRequest: CredentialRequestProtocol {
    required init(accessToken: String, issuerMetaData: IssuerMetadata, proof: JWTProof) {
    }

    func validateIssuerMetadata() -> ValidatorResult {
        let result = ValidatorResult(isValid: false)
        result.invalidFields = ["field1", "field2"]
        return result
    }

    func constructRequest() throws -> URLRequest {
        throw NSError(domain: "", code: -1)
    }
}

// MARK: - Helpers

func mockIssuerMetadata() -> IssuerMetadata {
    return IssuerMetadata(
        credentialAudience: "",
        credentialEndpoint: "",
        credentialType: [],
        context: nil, credentialFormat: CredentialFormat.ldp_vc,
        doctype: "",
        claims: [:],
        authorizationServers: nil,
        tokenEndpoint: nil,
        scope: ""
    )
}

func mockProof() -> Proof {
    return JWTProof(jwt: "")
}

// MARK: - Subclassed Factory to Inject Mocks

class TestableCredentialRequestFactory: CredentialRequestFactory {
    var credentialRequestToReturn: CredentialRequestProtocol!

    override func validateAndConstructCredentialRequest(credentialRequest: CredentialRequestProtocol) throws -> URLRequest {
        let validationResult = credentialRequestToReturn.validateIssuerMetadata()
        if validationResult.isValid {
            return try credentialRequestToReturn.constructRequest()
        } else {
            throw InvalidDataProvidedException("invalid fields: \(validationResult.invalidFields.joined(separator: ", "))")
        }
    }
}
final class MockAuthorizationCodeFlowService: AuthorizationCodeFlowService {
    var didCallRequestCredentials = false
    var shouldThrow = false
    var responseToReturn: CredentialResponse?

    override func requestCredentials(
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
        didCallRequestCredentials = true
        if shouldThrow {
            throw VCIClientException(code: "VCI-009", message: "Simulated error")
        }
        return responseToReturn!
    }
}
final class MockCredentialOfferService: CredentialOfferService {
    var offerToReturn: CredentialOffer!

    override func fetchCredentialOffer(_ offer: String) async throws -> CredentialOffer {
        return offerToReturn
    }
}

final class MockIssuerMetadataService: IssuerMetadataService {
    var resultToReturn: IssuerMetadataResult!

    override func fetch(
        issuerUrl: String,
        credentialConfigurationId: String
    ) async throws -> IssuerMetadataResult {
        return resultToReturn
    }
}

final class MockPreAuthFlowService: PreAuthFlowService {
    var didCallRequest = false
    var responseToReturn: CredentialResponse!

    override func requestCredentials(
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
        didCallRequest = true
        return responseToReturn
    }
}



