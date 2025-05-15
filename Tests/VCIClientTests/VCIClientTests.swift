
import XCTest
@testable import VCIClient

final class VCIClientTests: XCTestCase {
    func testRequestCredentialByCredentialOffer_success() async throws {
        let mockHandler = MockCredentialOfferHandler()
        let client = VCIClient(
            traceabilityId: "test",
            credentialOfferHandler: mockHandler
        )

        let result = try await client.requestCredentialByCredentialOffer(
            credentialOffer: "mock-offer",
            clientMetadata: ClientMetaData(clientId: "", redirectUri: ""), getTxCode: {_,_,_ in "mock-tx-code"},
            getProofJwt: { _, _, _, _ in "mock-jwt" },
            getAuthCode: { _ in "auth-code" }
        )

        XCTAssertNotNil(result)
        XCTAssertTrue(mockHandler.didCallDownload)
    }

    func testRequestCredentialByCredentialOffer_failure() async {
        let mockHandler = MockCredentialOfferHandler()
        mockHandler.shouldThrow = true

        let client = VCIClient(
            traceabilityId: "test",
            credentialOfferHandler: mockHandler
        )

        do {
            _ = try await client.requestCredentialByCredentialOffer(
                credentialOffer: "mock-offer",
                clientMetadata: ClientMetaData(clientId: "", redirectUri: ""), getTxCode: {_,_,_ in "mock-tx-code"},
                getProofJwt: { _, _, _, _ in "mock-jwt" },
                getAuthCode: { _ in "auth-code" }
            )
            XCTFail("Expected error but got success")
        } catch let error as VCIClientException {
            XCTAssertEqual(error.code, "VCI-009")
        } catch {
            XCTFail("Expected error did not occur")
        }
    }

    func testRequestCredentialFromTrustedIssuer_success() async throws {
        let mockHandler = MockTrustedIssuerHandler()
        let client = VCIClient(
            traceabilityId: "test",
            trustedIssuerHandler: mockHandler
        )

        let result = try await client.requestCredentialFromTrustedIssuer(
            issuerMetadata: IssuerMetadata(
                credentialAudience: "https://aud", credentialEndpoint: "", credentialFormat: CredentialFormat.ldp_vc
            ),
            clientMetadata: ClientMetaData(clientId: "", redirectUri: ""),
            getProofJwt: { _, _, _, _ in "mock-jwt" },
            getAuthCode: { _ in "auth-code" }
        )

        XCTAssertNotNil(result)
        XCTAssertTrue(mockHandler.didCallDownload)
    }

    func testRequestCredentialFromTrustedIssuer_failure() async {
        let mockHandler = MockTrustedIssuerHandler()
        mockHandler.shouldThrow = true

        let client = VCIClient(
            traceabilityId: "test",
            trustedIssuerHandler: mockHandler
        )

        do {
            _ = try await client.requestCredentialFromTrustedIssuer(
                issuerMetadata: IssuerMetadata(
                    credentialAudience: "https://aud", credentialEndpoint: "", credentialFormat: CredentialFormat.ldp_vc
                ),
                clientMetadata: ClientMetaData(clientId: "", redirectUri: ""),
                getProofJwt: { _, _, _, _ in "mock-jwt" },
                getAuthCode: { _ in "auth-code" }
            )
            XCTFail("Expected error but got success")
        } catch let error as VCIClientException {
            XCTAssertEqual(error.code, "VCI-009")
        } catch {
            XCTFail("Expected error did not occur")
        }
    }
}
