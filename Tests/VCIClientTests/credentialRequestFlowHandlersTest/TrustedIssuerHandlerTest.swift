import XCTest
@testable import VCIClient

final class TrustedIssuerHandlerTests: XCTestCase {
    func testDownloadCredentials_returnsResponse() async throws {
        let mockService = MockAuthorizationCodeFlowService()
        mockService.responseToReturn = CredentialResponse(credential: .init("mock"))

        let handler = TrustedIssuerHandler(authService: mockService)

        let result = try await handler.downloadCredentials(
            issuerMetadata: IssuerMetadata(credentialAudience: "aud", credentialEndpoint: "", credentialFormat: .ldp_vc),
            clientMetadata: ClientMetaData(clientId: "", redirectUri: ""),
            getAuthCode: { _ in "auth-code" },
            getProofJwt: { _, _, _, _ in "jwt" }
        )

        XCTAssertTrue(mockService.didCallRequestCredentials)
        XCTAssertEqual(try result?.toJsonString(), "{\n  \"credential\" : \"mock\"\n}")
    }

    func testDownloadCredentials_propagatesError() async {
        let mockService = MockAuthorizationCodeFlowService()
        mockService.shouldThrow = true

        let handler = TrustedIssuerHandler(authService: mockService)

        do {
            _ = try await handler.downloadCredentials(
                issuerMetadata: IssuerMetadata(credentialAudience: "aud", credentialEndpoint: "", credentialFormat: .ldp_vc),
                clientMetadata: ClientMetaData(clientId: "", redirectUri: ""),
                getAuthCode: { _ in "auth-code" },
                getProofJwt: { _, _, _, _ in "jwt" }
            )
            XCTFail("Expected error but got success")
        } catch let error as VCIClientException {
            XCTAssertEqual(error.code, "VCI-009")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
