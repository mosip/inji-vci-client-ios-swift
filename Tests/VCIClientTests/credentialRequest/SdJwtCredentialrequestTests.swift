import XCTest
@testable import VCIClient

final class SdJwtCredentialRequestTests: XCTestCase {

    var credentialRequest: SdJwtCredentialRequest!
    let accessToken = "AccessToken"
    let proofJWT = JWTProof(jwt: "xxxx.yyyy.zzzz")

    override func setUp() {
        super.setUp()
        let issuer = IssuerMetadata(
            credentialIssuer: "https://issuer.example.com",
            credentialEndpoint: "https://issuer.example.com/credential",
            credentialFormat: .vc_sd_jwt,
            claims: ["given_name": AnyCodable("Alice")], vct: "IdentityCredential"
        )
        credentialRequest = SdJwtCredentialRequest(accessToken: accessToken, issuerMetaData: issuer, proof: proofJWT)
    }

    override func tearDown() {
        credentialRequest = nil
        super.tearDown()
    }

    func testConstructRequest_shouldReturnValidRequest_whenMetadataIsValid() {
        do {
            let request = try credentialRequest.constructRequest()

            XCTAssertEqual(request.url?.absoluteString, "https://issuer.example.com/credential")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json")
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer \(accessToken)")
            XCTAssertNotNil(request.httpBody)

            if let bodyData = request.httpBody,
               let bodyString = String(data: bodyData, encoding: .utf8) {
                XCTAssertTrue(bodyString.contains("\"vct\":\"IdentityCredential\""))
                XCTAssertTrue(bodyString.contains("\"jwt\":\"xxxx.yyyy.zzzz\""))
                XCTAssertTrue(bodyString.contains("\"given_name\""))
                XCTAssertTrue(bodyString.contains("\"Alice\""))
            } else {
                XCTFail("Request body is nil or not convertible to string")
            }

        } catch {
            XCTFail("Unexpected error during request construction: \(error)")
        }
    }

    func testConstructRequest_shouldThrow_whenVctIsMissing() {
        let issuerMissingVct = IssuerMetadata(
            credentialIssuer: "https://issuer.example.com",
            credentialEndpoint: "https://issuer.example.com/credential",
            credentialFormat: .vc_sd_jwt,
            claims: ["family_name": AnyCodable("Paul")]
        )

        let requestWithMissingVct = SdJwtCredentialRequest(accessToken: accessToken, issuerMetaData: issuerMissingVct, proof: proofJWT)

        XCTAssertThrowsError(try requestWithMissingVct.constructRequest()) { error in
            guard let downloadError = error as? DownloadFailedException else {
                return XCTFail("Expected DownloadFailedException but got \(type(of: error))")
            }
            XCTAssertTrue(downloadError.localizedDescription.contains("Missing 'vct'"))
        }
    }

    func testValidateIssuerMetadata_shouldReturnValid_whenVctIsPresent() {
        let result = credentialRequest.validateIssuerMetadata()
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.invalidFields.isEmpty)
    }

    func testValidateIssuerMetadata_shouldReturnInvalid_whenVctIsMissing() {
        let issuerMissingVct = IssuerMetadata(
            credentialIssuer: "https://issuer.example.com",
            credentialEndpoint: "https://issuer.example.com/credential",
            credentialFormat: .vc_sd_jwt
        )

        let requestWithMissingVct = SdJwtCredentialRequest(accessToken: accessToken, issuerMetaData: issuerMissingVct, proof: proofJWT)
        let result = requestWithMissingVct.validateIssuerMetadata()

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.invalidFields, ["vct"])
    }
}
