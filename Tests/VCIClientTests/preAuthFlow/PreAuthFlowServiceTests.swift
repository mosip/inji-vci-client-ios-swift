
@testable import VCIClient
import XCTest
final class PreAuthFlowServiceTests: XCTestCase {
    func makeService(
        resolver: AuthServerResolver = MockAuthServerResolver(),
        tokenService: TokenService = MockTokenService(),
        executor: CredentialRequestExecutor = MockCredentialRequestExecutor()
    ) -> PreAuthFlowService {
        return PreAuthFlowService(
            authServerResolver: resolver,
            tokenService: tokenService,
            credentialExecutor: executor
        )
    }

    func test_requestCredentials_success() async throws {
        let service = makeService()

        let issuerMetadata = IssuerMetadata.mock()
        let offer = CredentialOffer.mockWithTxCodeRequired()
        let rawMetadata = ["key": "value"]

        let result = try await service.requestCredentials(
            issuerMetadataResult: IssuerMetadataResult(issuerMetadata: IssuerMetadata.mock(), raw: rawMetadata),
            offer: offer,
            getTxCode: { _, _, _ in "tx123" },
            getProofJwt: { _, _, _, _ in "jwt-mock" },
            credentialConfigurationId: "vc1"
        )

        XCTAssertEqual(result.credential.value as? String, "mock-credential")
    }

    func test_requestCredentials_missingTokenEndpoint_shouldThrow() async {
        let resolver = MockAuthServerResolver()
        resolver.mockTokenEndpoint = nil

        let service = makeService(resolver: resolver)

        do {
            _ = try await service.requestCredentials(
                issuerMetadataResult: IssuerMetadataResult(issuerMetadata: IssuerMetadata.mock(), raw: [:]),
                offer: CredentialOffer.mock(),
                getProofJwt: { _, _, _, _ in "jwt" },
                credentialConfigurationId: "vc1"
            )
            XCTFail("Expected failure due to missing token endpoint")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Token endpoint is missing"))
        }
    }

    func test_requestCredentials_txCodeRequiredButNotProvided_shouldThrow() async {
        let service = makeService()

        do {
            _ = try await service.requestCredentials(
                issuerMetadataResult: IssuerMetadataResult(issuerMetadata: IssuerMetadata.mock(), raw: [:]),
                offer: CredentialOffer.mockWithTxCodeRequired(),
                getTxCode: nil,
                getProofJwt: { _, _, _, _ in "jwt" },
                credentialConfigurationId: "vc1"
            )
            XCTFail("Expected failure due to missing tx_code provider")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("tx_code required"))
        }
    }

    func test_requestCredentials_missingGrant_shouldThrow() async {
        let service = makeService()

        let offer = CredentialOffer.mockWithoutGrant()

        do {
            _ = try await service.requestCredentials(
                issuerMetadataResult: IssuerMetadataResult(issuerMetadata: IssuerMetadata.mock(), raw: [:]),
                offer: offer,
                getProofJwt: { _, _, _, _ in "jwt" },

                credentialConfigurationId: "vc1"
            )
            XCTFail("Expected failure due to missing grant")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing pre-authorized grant details"))
        }
    }

    func test_requestCredentials_credentialDownloadFails_shouldThrow() async {
        let failingExecutor = MockCredentialRequestExecutor(shouldReturnNil: true)
        let service = makeService(executor: failingExecutor)

        do {
            _ = try await service.requestCredentials(
                issuerMetadataResult: IssuerMetadataResult(issuerMetadata: IssuerMetadata.mock(), raw: [:]),
                offer: CredentialOffer.mock(),
                getProofJwt: { _, _, _, _ in "jwt" },
                credentialConfigurationId: "vc1"
            )
            XCTFail("Expected failure due to credential download returning nil")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Credential request failed"))
        }
    }
}
