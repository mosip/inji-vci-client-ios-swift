
@testable import VCIClient
import XCTest
final class AuthorizationCodeFlowServiceTests: XCTestCase {
    func makeService(
        resolver: AuthServerResolver = MockAuthServerResolver(),
        tokenService: TokenService = MockTokenService(),
        executor: CredentialRequestExecutor = MockCredentialRequestExecutor(),
        pkceManager: PKCESessionManager = MockPKCESessionManager()
    ) -> AuthorizationCodeFlowService {
        return AuthorizationCodeFlowService(
            authServerResolver: resolver,
            tokenService: tokenService,
            credentialExecutor: executor,
            pkceSessionManager: pkceManager
        )
    }

    func test_requestCredentials_success() async throws {
        let service = makeService()

        let result = try await service.requestCredentials(
            issuerMetadataResult: IssuerMetadataResult(issuerMetadata: IssuerMetadata.mock(), raw: [:]),
            clientMetadata: ClientMetaData(clientId: "client123", redirectUri: "app://redirect"),
            getAuthCode: { _ in "auth-code" },
            getProofJwt: { _, _, _, _ in "mock-jwt" },
            credentialConfigurationId: "vc1"
        )

        XCTAssertEqual(result.credential.value as? String, "mock-credential")
    }

    func test_missingAuthorizationEndpoint_shouldThrow() async {
        let resolver = MockAuthServerResolver()
        resolver.mcokAuthorizationEndpoint = nil

        let service = makeService(resolver: resolver)

        do {
            _ = try await service.requestCredentials(
                issuerMetadataResult: IssuerMetadataResult(issuerMetadata: IssuerMetadata.mock(), raw: [:]),
                clientMetadata: ClientMetaData(clientId: "client", redirectUri: "uri"),
                getAuthCode: { _ in "code" },
                getProofJwt: { _, _, _, _ in "jwt" }
            )
            XCTFail("Expected to throw due to missing authorization endpoint")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing authorization endpoint"))
        }
    }

    func test_missingTokenEndpoint_shouldThrow() async {
        let resolver = MockAuthServerResolver()
        resolver.mockTokenEndpoint = nil

        let service = makeService(resolver: resolver)

        do {
            _ = try await service.requestCredentials(
                issuerMetadataResult: IssuerMetadataResult(issuerMetadata: IssuerMetadata(credentialAudience: "", credentialEndpoint: "", credentialFormat: .mso_mdoc, doctype: "d", claims: nil, authorizationServers: nil), raw: [:]),
                clientMetadata: ClientMetaData(clientId: "c", redirectUri: "r"),
                getAuthCode: { _ in "auth" },
                getProofJwt: { _, _, _, _ in "jwt" }
            )
            XCTFail("Expected to throw due to missing token endpoint")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing token endpoint"))
        }
    }

    func test_credentialDownloadNil_shouldThrow() async {
        let executor = MockCredentialRequestExecutor(shouldReturnNil: true)
        let service = makeService(executor: executor)

        do {
            _ = try await service.requestCredentials(
                issuerMetadataResult: IssuerMetadataResult(issuerMetadata: IssuerMetadata.mock(), raw: [:]),
                clientMetadata: ClientMetaData(clientId: "x", redirectUri: "y"),
                getAuthCode: { _ in "auth" },
                getProofJwt: { _, _, _, _ in "jwt" }
            )
            XCTFail("Expected to throw due to nil credential response")
        } catch {
            print("-------", error.localizedDescription)
            XCTAssertTrue(error.localizedDescription.contains("Credential request returned nil"))
        }
    }
}
