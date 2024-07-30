import XCTest
@testable import VCIClient

class VCIClientTests: XCTestCase {
    
    var client: VCIClient!
    var mockSession: MockNetworkSession!
    
    override func setUp() {
        super.setUp()
        mockSession = MockNetworkSession()
        client = VCIClient(traceabilityId: "VCI-client-test", networkSession: mockSession)
    }
    
    override func tearDown() {
        mockSession = nil
        client = nil
        super.tearDown()
    }
    
    func testRequestCredentialSuccess() async {
        let mockCredentialResponseData = """
        {
          "format": "ldp_vc",
          "credential": {
            "issuer": "https://domain.net/credentials/",
            "issuanceDate": "2024-05-12T16:12:47.266Z",
            "id": "https://domain.net/credentials/858c69d7-676a-4f19-ba51-d9ed754f2935",
            "proof": {
              "proofPurpose": "assertionMethod",
              "created": "2024-05-12T16:12:47Z",
              "jws": "eyJr80435=",
              "verificationMethod": "https://domain.net/.well-known/ida-public-key.json",
              "type": "RsaSignature2018"
            },
            "credentialSubject": {
              "gender": [
                {
                  "value": "Male",
                  "language": "eng"
                }
              ],
              "phone": "9876567893",
              "city": [
                {
                  "value": "Kenitra",
                  "language": "eng"
                }
              ],
              "id": "did:jwk:eyJrdHkiOi==",
              "dateOfBirth": "1999/01/01",
              "fullName": [
                {
                  "value": "santhush",
                  "language": "eng"
                }
              ],
              "face": "daVqaL0H1oorC",
              "addressLine1": [
                {
                  "value": "saravangar",
                  "language": "eng"
                }
              ],
              "email": "sunthoush@gmail.com",
              "UIN": "9612973623"
            },
            "type": [
              "VerifiableCredential",
              "MOSIPVerifiableCredential"
            ],
            "@context": [
              "https://www.domain.org/2018/credentials/v1",
              "https://api.domain.net/.well-known/domain-context.json",
              {
                "sec": "https://w3id.org/security#"
              }
            ]
          }
        }
        """.data(using: .utf8)!
        
        
        
        let mockCredentialResponse = HTTPURLResponse(url: URL(string: "https://domain.net/credentials/12345-87435")!,
                                                     statusCode: 200,
                                                     httpVersion: "1.1",
                                                     headerFields: ["Content-Type": "application/json"])!
        
        mockSession.data = mockCredentialResponseData
        mockSession.response = mockCredentialResponse
        
        let issuerMeta = IssuerMeta(credentialAudience: "https://domain.net",
                                    credentialEndpoint: "https://domain.net/credential",
                                    downloadTimeoutInMilliseconds: 20000,
                                    credentialType: ["VerifiableCredential"],
                                    credentialFormat: .ldp_vc)
        let accessToken = "YourAccessToken"
        let proofJWT = "YourProofJWT"
        
        do {
            let response = try await client.requestCredential(issuerMeta: issuerMeta,
                                                              proof: JWTProof(jwt: proofJWT),
                                                              accessToken: accessToken)
            XCTAssertNotNil(response)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    
    func testRequestCredentialSuccessDraft13()async{
        let mockCredentialResponseDataDraft13 = """
               {
                  "credential": {
                   "issuer": "https://domain.net/credentials/",
                   "issuanceDate": "2024-05-12T16:12:47.266Z",
                   "id": "https://domain.net/credentials/858c69d7-676a-4f19-ba51-d9ed754f2935",
                   "proof": {
                     "proofPurpose": "assertionMethod",
                     "created": "2024-05-12T16:12:47Z",
                     "jws": "eyJr80435=",
                     "verificationMethod": "https://domain.net/.well-known/ida-public-key.json",
                     "type": "RsaSignature2018"
                   },
                   "credentialSubject": {
                     "gender": [
                       {
                         "value": "Male",
                         "language": "eng"
                       }
                     ],
                     "phone": "9876567893",
                     "city": [
                       {
                         "value": "Kenitra",
                         "language": "eng"
                       }
                     ],
                     "id": "did:jwk:eyJrdHkiOi==",
                     "dateOfBirth": "1999/01/01",
                     "fullName": [
                       {
                         "value": "santhush",
                         "language": "eng"
                       }
                     ],
                     "face": "daVqaL0H1oorC",
                     "addressLine1": [
                       {
                         "value": "saravangar",
                         "language": "eng"
                       }
                     ],
                     "email": "sunthoush@gmail.com",
                     "UIN": "9612973623"
                   },
                   "type": [
                     "VerifiableCredential",
                     "MOSIPVerifiableCredential"
                   ],
                   "@context": [
                     "https://www.domain.org/2018/credentials/v1",
                     "https://api.domain.net/.well-known/domain-context.json",
                     {
                       "sec": "https://w3id.org/security#"
                     }
                   ]
                 }
               }
        """.data(using: .utf8)
        
        let mockCredentialResponseDraft13 = HTTPURLResponse(url: URL(string: "https://domain.net/credentials/12345-87435")!,
                                                            statusCode: 200,
                                                            httpVersion: "1.1",
                                                            headerFields: ["Content-Type": "application/json"])!
        
        mockSession.data = mockCredentialResponseDataDraft13
        mockSession.response = mockCredentialResponseDraft13
        
        let issuerMeta = IssuerMeta(credentialAudience: "https://domain.net",
                                    credentialEndpoint: "https://domain.net/credential",
                                    downloadTimeoutInMilliseconds: 20000,
                                    credentialType: ["VerifiableCredential"],
                                    credentialFormat: .ldp_vc)
        let accessToken = "YourAccessToken"
        let proofJWT = "YourProofJWT"
        
        do {
            let response = try await client.requestCredential(issuerMeta: issuerMeta,
                                                              proof: JWTProof(jwt: proofJWT),
                                                              accessToken: accessToken)
            XCTAssertNotNil(response)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRequestCredentialFailure() async {
        let mockErrorResponseData = """
        {
            "error": "InvalidPublicKeyError",
            "message": "keyPrimitiveExtractionFailed"
        }
        """.data(using: .utf8)!
        let mockErrorResponse = HTTPURLResponse(url: URL(string: "https://domain.net/credentials/12345-87435")!,
                                                statusCode: 401,
                                                httpVersion: "1.1",
                                                headerFields: ["Content-Type": "application/json"])!
        
        mockSession.data = mockErrorResponseData
        mockSession.response = mockErrorResponse
        
        let issuerMeta = IssuerMeta(credentialAudience: "https://domain.net",
                                    credentialEndpoint: "https://domain.net/credential",
                                    downloadTimeoutInMilliseconds: 20000,
                                    credentialType: ["VerifiableCredential"],
                                    credentialFormat: .ldp_vc)
        let accessToken = "YourAccessToken"
        let proofJWT = "YourProofJWT"
        
        do {
            let _ = try await client.requestCredential(issuerMeta: issuerMeta,
                                                       proof: JWTProof(jwt: proofJWT),
                                                       accessToken: accessToken)
            
            XCTFail("Expected an error but call succeeded")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "VCIClient.DownloadFailedError")
            
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
