@testable import VCIClient
import XCTest

final class CredentialRequestFactoryTests: XCTestCase {

    func testCreateCredentialRequest_ldpvc_returnsValidRequest() throws {
        let factory = TestableCredentialRequestFactory()
        factory.credentialRequestToReturn = MockValidCredentialRequest(
            accessToken: "token",
            issuerMetaData: mockIssuerMetadata(),
            proof: JWTProof(jwt: "")
        )

        let request = try factory.createCredentialRequest(
            credentialFormat: .ldp_vc,
            accessToken: "token",
            issuer: mockIssuerMetadata(),
            proofJwt: mockProof()
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.com")
    }

    func testCreateCredentialRequest_msomdoc_returnsValidRequest() throws {
        let factory = TestableCredentialRequestFactory()
        factory.credentialRequestToReturn = MockValidCredentialRequest(
            accessToken: "token",
            issuerMetaData: mockIssuerMetadata(),
            proof: JWTProof(jwt: "")
        )

        let request = try factory.createCredentialRequest(
            credentialFormat: .mso_mdoc,
            accessToken: "token",
            issuer: mockIssuerMetadata(),
            proofJwt: mockProof()
        )

        XCTAssertEqual(request.url?.absoluteString, "https://example.com")
    }

    func testCreateCredentialRequest_invalidValidation_throwsException() {
        let factory = TestableCredentialRequestFactory()
        factory.credentialRequestToReturn = MockInvalidCredentialRequest(
            accessToken: "token",
            issuerMetaData: mockIssuerMetadata(),
            proof: JWTProof(jwt: "")
        )

        XCTAssertThrowsError(
            try factory.createCredentialRequest(
                credentialFormat: .ldp_vc,
                accessToken: "token",
                issuer: mockIssuerMetadata(),
                proofJwt: mockProof()
            )
        ) { error in
            XCTAssertTrue(error is InvalidDataProvidedException)
        }
    }
}
