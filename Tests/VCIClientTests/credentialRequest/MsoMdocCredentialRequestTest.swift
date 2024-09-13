import XCTest
@testable import VCIClient

final class MsoMdocCredentialRequestTest: XCTestCase {

    var credentialRequest: MsoMdocVcCredentialRequest!
    let url = URL(string: "https://domain.net/credential")!
    let accessToken = "AccessToken"
    let issuer = IssuerMeta(credentialAudience: "https://domain.net",
                            credentialEndpoint: "https://domain.net/credential",
                            downloadTimeoutInMilliseconds: 20000,
                            credentialFormat: .mso_mdoc,
                            docType: "org.iso.18013.5.1.mDL",
                            claims: ["org.iso.18013.5.1":["given_name": [String: String]()]])
    let proofJWT = JWTProof(jwt: "ProofJWT")
    
    override func setUp() {
        super.setUp()
        credentialRequest = MsoMdocVcCredentialRequest(accessToken: accessToken, issuerMetaData: issuer, proof: proofJWT)
    }
    
    override func tearDown() {
        credentialRequest = nil
        super.tearDown()
    }


    func testConstructRequestSuccess() {
        do {
            let request = try credentialRequest.constructRequest()
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json")
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer \(accessToken)")
            XCTAssertEqual(request.timeoutInterval, TimeInterval(issuer.downloadTimeoutInMilliseconds / 1000))
            XCTAssertNotNil(request.httpBody)
        } catch {
            XCTFail("Error: \(error.localizedDescription)")
        }
    }
    
    func testshouldReturnValidatorResultWithIsValidAsTrueWhenRequiredIssuerMetadataDetailsOfMsoMdocVcAreAvailable() {
        credentialRequest = MsoMdocVcCredentialRequest(accessToken: accessToken, issuerMetaData: issuer, proof: proofJWT)
        
        let validationResult = credentialRequest.validateIssuerMetadata()
        
        XCTAssertTrue(validationResult.isValid)
        XCTAssert(validationResult.invalidFields.count==0)
    }
    
    func testshouldReturnValidatorResultWithIsValidAsFalseWithInvalidFieldsWhenRequiredDocTypeIsNotAvailableInIssuerMetadata() {
        let issuerMetadataWithoutDocType = IssuerMeta(credentialAudience: "https://domain.net",
                                credentialEndpoint: "https://domain.net/credential",
                                downloadTimeoutInMilliseconds: 20000,
                                credentialFormat: .mso_mdoc,
                                claims: ["org.iso.18013.5.1":["given_name": [String: String]()]])
        credentialRequest = MsoMdocVcCredentialRequest(accessToken: accessToken, issuerMetaData: issuerMetadataWithoutDocType, proof: proofJWT)
        
        let validationResult = credentialRequest.validateIssuerMetadata()
        
        XCTAssertFalse(validationResult.isValid)
        XCTAssert(validationResult.invalidFields.elementsEqual(["docType"]))
    }

    func testshouldReturnValidatorResultWithIsValidAsFalseWithInvalidFieldsWhenRequiredClaimsIsNotAvailableInIssuerMetadata() {
        let issuerMetadataWithoutDocType = IssuerMeta(credentialAudience: "https://domain.net",
                                credentialEndpoint: "https://domain.net/credential",
                                downloadTimeoutInMilliseconds: 20000,
                                credentialFormat: .mso_mdoc,
                                                      docType: "org.iso.18013.5.1.mDL")
        credentialRequest = MsoMdocVcCredentialRequest(accessToken: accessToken, issuerMetaData: issuerMetadataWithoutDocType, proof: proofJWT)
        
        let validationResult = credentialRequest.validateIssuerMetadata()
        
        XCTAssertFalse(validationResult.isValid)
        XCTAssert(validationResult.invalidFields.elementsEqual(["claims"]))
    }
    
    func testshouldReturnValidatorResultWithIsValidAsFalseWithInvalidFieldsWhenRequiredDocTypeAndClaimsAreNotAvailableInIssuerMetadata() {
        let issuerMetadataWithoutDocType = IssuerMeta(credentialAudience: "https://domain.net",
                                credentialEndpoint: "https://domain.net/credential",
                                downloadTimeoutInMilliseconds: 20000,
                                credentialFormat: .mso_mdoc
                                                      )
        credentialRequest = MsoMdocVcCredentialRequest(accessToken: accessToken, issuerMetaData: issuerMetadataWithoutDocType, proof: proofJWT)
        
        let validationResult = credentialRequest.validateIssuerMetadata()
        
        XCTAssertFalse(validationResult.isValid)
        XCTAssert(validationResult.invalidFields.elementsEqual(["docType","claims"]))
        
    }
}
