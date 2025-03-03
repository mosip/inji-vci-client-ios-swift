import XCTest
@testable import VCIClient

class CredentialResponseTest: XCTestCase {
    func testCredentialResponse() {
        do {
            let responseBodyJsonData = """
            {
                "credential": {
                    "credentialSubject": {
                        "id": "did:jwk:eyJr80435",
                        "dateOfBirth": "2000/01/01",
                        "UIN": "9012378996",
                        "face": "data:image/jpeg;base64,9j/goKCyuig",
                        "email": "mockuser@gmail.com"
                    },
                    "type": [
                        "VerifiableCredential"
                    ],
                    "issuanceDate": "2024-04-14T16:04:35.304Z",
                    "expirationDate": "2024-07-28T11:41:43.216Z",
                    "@context": [
                        "https://www.w3.org/2018/credentials/v1",
                        "https://domain.net/.well-known/context.json",
                        {
                            "sec": "https://w3id.org/security#"
                        }
                    ],
                    "id": "https://domain.net/credentials/12345-87435",
                    "issuer": "https://domain.net/.well-known/issuer.json",
                    "proof": {
                        "type": "RsaSignature2018",
                        "proofPurpose": "assertionMethod",
                        "created": "2024-04-14T16:04:35Z",
                        "jws": "eyJiweyrtwegrfwwaBKCGSwxjpa5suaMtgnQ",
                        "proofValue": "23sx",
                        "verificationMethod": "https://domain.net/.well-known/public-key.json"
                    }
                }
            }
            """.data(using: .utf8)!

            let credentialResponse = try JSONDecoder().decode(CredentialResponse.self, from: responseBodyJsonData)
            let credentialResponseJsonData = try credentialResponse.toJsonString().data(using: .utf8)!


            
            let expectedJsonObject = try JSONSerialization.jsonObject(with: responseBodyJsonData, options: []) as? [String: Any]
            let actualJsonObject = try JSONSerialization.jsonObject(with: credentialResponseJsonData, options: []) as? [String: Any]

            XCTAssertEqual(expectedJsonObject as NSDictionary?, actualJsonObject as NSDictionary?)
        } catch {
            XCTFail("Error occurred while testing CredentialResponse: \(error)")
        }
    }
}
