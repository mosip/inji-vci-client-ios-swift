
import XCTest
@testable import VCIClient
final class IssuerMetadataServiceTests: XCTestCase {

    func makeService(response: String, shouldThrow: Bool = false) -> IssuerMetadataService {
        let mock = MockNetworkManager()
        mock.responseBody = response
        mock.shouldThrowNetworkError = shouldThrow
        return IssuerMetadataService(session: mock)
    }

    func test_fetch_mso_mdoc_success() async throws {
        let json = """
        {
          "credential_issuer": "https://issuer.com",
          "credential_endpoint": "https://issuer.com/credential",
          "credential_configurations_supported": {
            "mdoc": {
              "format": "mso_mdoc",
              "doctype": "org.iso.18013.5.1.mDL",
              "claims": {
                "name": "John",
                "dob": "1990-01-01"
              }
            }
          }
        }
        """

        let service = makeService(response: json)
        let result = try await service.fetchIssuerMetadataResult(credentialIssuer: "https://issuer.com", credentialConfigurationId: "mdoc")

        XCTAssertEqual(result.issuerMetadata.credentialIssuer, "https://issuer.com")
        XCTAssertEqual(result.issuerMetadata.credentialFormat, .mso_mdoc)
        XCTAssertEqual(result.issuerMetadata.doctype, "org.iso.18013.5.1.mDL")
    }

    func test_fetch_ldp_vc_success_with_scope() async throws {
        let json = """
        {
          "credential_issuer": "https://issuer.com",
          "credential_endpoint": "https://issuer.com/credential",
          "authorization_servers": ["https://auth.issuer.com"],
          "credential_configurations_supported": {
            "vc1": {
              "format": "ldp_vc",
              "scope": "identity",
              "credential_definition": {
                "type": ["VerifiableCredential", "ProfileCredential"],
                "@context": ["https://www.w3.org/2018/credentials/v1"]
              }
            }
          }
        }
        """

        let service = makeService(response: json)
        let result = try await service.fetchIssuerMetadataResult(credentialIssuer:  "https://issuer.com", credentialConfigurationId: "vc1")

        XCTAssertEqual(result.issuerMetadata.credentialIssuer, "https://issuer.com")
        XCTAssertEqual(result.issuerMetadata.credentialFormat, .ldp_vc)
        XCTAssertEqual(result.issuerMetadata.credentialType, ["VerifiableCredential", "ProfileCredential"])
        XCTAssertEqual(result.issuerMetadata.scope, "identity")
        XCTAssertEqual(result.issuerMetadata.authorizationServers, ["https://auth.issuer.com"])
    }

    func test_fetch_emptyResponse_shouldThrow() async {
        let service = makeService(response: "")

        do {
            _ = try await service.fetchIssuerMetadataResult(credentialIssuer: "https://issuer.com", credentialConfigurationId: "vc1")
            XCTFail("Expected error for empty response")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("response is empty"))
        }
    }


    func test_fetch_missingCredentialConfiguration_shouldThrow() async {
        let json = """
        {
          "credential_issuer": "https://issuer.com",
          "credential_endpoint": "https://issuer.com/credential"
        }
        """
        let service = makeService(response: json)

        do {
            _ = try await service.fetchIssuerMetadataResult(credentialIssuer: "https://issuer.com", credentialConfigurationId: "vc1")
            XCTFail("Expected error for missing credential configuration")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("credential configuration"))
        }
    }

    func test_fetch_missingFormat_shouldThrow() async {
        let json = """
        {
          "credential_issuer": "https://issuer.com",
          "credential_endpoint": "https://issuer.com/credential",
          "credential_configurations_supported": {
            "vc1": {
              "scope": "identity"
            }
          }
        }
        """
        let service = makeService(response: json)

        do {
            _ = try await service.fetchIssuerMetadataResult(credentialIssuer: "https://issuer.com", credentialConfigurationId: "vc1")
            XCTFail("Expected error for missing format")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("credential format"))
        }
    }

    func test_fetch_missingDoctypeInMdoc_shouldThrow() async {
        let json = """
        {
          "credential_issuer": "https://issuer.com",
          "credential_endpoint": "https://issuer.com/credential",
          "credential_configurations_supported": {
            "mdoc": {
              "format": "mso_mdoc"
            }
          }
        }
        """
        let service = makeService(response: json)

        do {
            _ = try await service.fetchIssuerMetadataResult(credentialIssuer: "https://issuer.com", credentialConfigurationId: "mdoc")
            XCTFail("Expected error for missing doctype")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing doctype"))
        }
    }

    func test_fetch_invalidFormat_shouldThrow() async {
        let json = """
        {
          "credential_issuer": "https://issuer.com",
          "credential_endpoint": "https://issuer.com/credential",
          "credential_configurations_supported": {
            "conf1": {
              "format": "unsupported_format"
            }
          }
        }
        """
        let service = makeService(response: json)

        do {
            _ = try await service.fetchIssuerMetadataResult(credentialIssuer: "https://issuer.com", credentialConfigurationId: "conf1")
            XCTFail("Expected error for unsupported credential format")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("credential format"))
        }
    }

    func test_fetch_networkFailure_shouldThrow() async {
        let service = makeService(response: "{}", shouldThrow: true)

        do {
            _ = try await service.fetchIssuerMetadataResult(credentialIssuer: "https://issuer.com", credentialConfigurationId: "vc1")
            XCTFail("Expected error for network failure")
        } catch {
            print("--------",error.localizedDescription)
            XCTAssertTrue(error.localizedDescription.contains("Simulated network failure"))
        }
    }
    
    func testFetch_shouldReturnSdJwtMetadata_whenValidJsonIsProvided() async throws {
        let json = """
        {
          "credential_issuer": "https://issuer.com",
          "credential_endpoint": "https://issuer.com/credential",
          "authorization_servers": ["https://auth.issuer.com"],
          "credential_configurations_supported": {
            "vc_sd": {
              "format": "vc+sd-jwt",
              "vct": "IdentityCredential",
              "scope": "identity",
              "claims": {
                "given_name": {
                  "display": [
                    {
                      "name": "Given Name",
                      "locale": "en-US"
                    },
                    {
                      "name": "Vorname",
                      "locale": "de-DE"
                    }
                  ]
                }
              }
            }
          }
        }
        """

        let service = makeService(response: json)
        let result = try await service.fetchIssuerMetadataResult(
            credentialIssuer: "https://issuer.com",
            credentialConfigurationId: "vc_sd"
        )

        let metadata = result.issuerMetadata
        XCTAssertEqual(metadata.credentialIssuer, "https://issuer.com")
        XCTAssertEqual(metadata.credentialEndpoint, "https://issuer.com/credential")
        XCTAssertEqual(metadata.credentialFormat, .vc_sd_jwt)
        XCTAssertEqual(metadata.vct, "IdentityCredential")
        XCTAssertEqual(metadata.scope, "identity")
        XCTAssertEqual(metadata.authorizationServers, ["https://auth.issuer.com"])

        
        let givenNameClaim = metadata.claims?["given_name"]?.value as? [String: Any]
        XCTAssertNotNil(givenNameClaim)
        let displayArray = givenNameClaim?["display"] as? [[String: Any]]
        XCTAssertEqual(displayArray?.count, 2)
        XCTAssertEqual(displayArray?.first?["name"] as? String, "Given Name")
        XCTAssertEqual(displayArray?.first?["locale"] as? String, "en-US")
    }
    
    func testFetch_shouldThrow_whenVctIsMissingInSdJwtConfiguration() async {
        let json = """
        {
          "credential_issuer": "https://issuer.com",
          "credential_endpoint": "https://issuer.com/credential",
          "credential_configurations_supported": {
            "vc_sd": {
              "format": "vc+sd-jwt",
              "scope": "identity",
              "claims": {
                "given_name": {
                  "display": [
                    {
                      "name": "Given Name",
                      "locale": "en-US"
                    }
                  ]
                }
              }
            }
          }
        }
        """

        let service = makeService(response: json)

        do {
            _ = try await service.fetchIssuerMetadataResult(
                credentialIssuer: "https://issuer.com",
                credentialConfigurationId: "vc_sd"
            )
            XCTFail("Expected IssuerMetadataFetchException due to missing vct")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing vct"), "Unexpected error: \(error.localizedDescription)")
        }
    }
    
    func testFetch_shouldReturnDcSdJwtMetadata_whenValidJsonIsProvided() async throws {
        let json = """
        {
          "credential_issuer": "https://issuer.com",
          "credential_endpoint": "https://issuer.com/credential",
          "authorization_servers": ["https://auth.issuer.com"],
          "credential_configurations_supported": {
            "dc_sd": {
              "format": "dc+sd-jwt",
              "vct": "DocumentCredential",
              "scope": "identity",
              "claims": {
                "document_id": {
                  "display": [
                    {
                      "name": "Document ID",
                      "locale": "en-US"
                    }
                  ]
                }
              }
            }
          }
        }
        """

        let service = makeService(response: json)
        let result = try await service.fetchIssuerMetadataResult(
            credentialIssuer: "https://issuer.com",
            credentialConfigurationId: "dc_sd"
        )

        let metadata = result.issuerMetadata
        XCTAssertEqual(metadata.credentialIssuer, "https://issuer.com")
        XCTAssertEqual(metadata.credentialEndpoint, "https://issuer.com/credential")
        XCTAssertEqual(metadata.credentialFormat, .dc_sd_jwt)
        XCTAssertEqual(metadata.vct, "DocumentCredential")
        XCTAssertEqual(metadata.scope, "identity")
        XCTAssertEqual(metadata.authorizationServers, ["https://auth.issuer.com"])

        let docIdClaim = metadata.claims?["document_id"]?.value as? [String: Any]
        XCTAssertNotNil(docIdClaim)
        let displayArray = docIdClaim?["display"] as? [[String: Any]]
        XCTAssertEqual(displayArray?.count, 1)
        XCTAssertEqual(displayArray?.first?["name"] as? String, "Document ID")
        XCTAssertEqual(displayArray?.first?["locale"] as? String, "en-US")
    }
    
    func testFetch_shouldThrow_whenVctIsMissingInDcSdJwtConfiguration() async {
        let json = """
        {
          "credential_issuer": "https://issuer.com",
          "credential_endpoint": "https://issuer.com/credential",
          "credential_configurations_supported": {
            "dc_sd": {
              "format": "dc+sd-jwt",
              "scope": "identity",
              "claims": {
                "document_id": {
                  "display": [
                    {
                      "name": "Document ID",
                      "locale": "en-US"
                    }
                  ]
                }
              }
            }
          }
        }
        """

        let service = makeService(response: json)

        do {
            _ = try await service.fetchIssuerMetadataResult(
                credentialIssuer: "https://issuer.com",
                credentialConfigurationId: "dc_sd"
            )
            XCTFail("Expected IssuerMetadataFetchException due to missing vct")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing vct"), "Unexpected error: \(error.localizedDescription)")
        }
    }
    
    func test_fetchCredentialConfigurationsSupported_success() async throws {
        let json = """
        {
          "credential_configurations_supported": {
            "vc1": {
              "format": "ldp_vc"
            },
            "vc2": {
              "format": "mso_mdoc",
              "doctype": "org.iso.18013.5.1.mDL"
            }
          }
        }
        """
        let service = makeService(response: json)
        let configs = try await service.fetchCredentialConfigurationsSupported(from: "https://issuer.com")
        
        XCTAssertEqual(configs.count, 2)
        XCTAssertNotNil(configs["vc1"])
        XCTAssertEqual((configs["vc1"] as? [String: Any])?["format"] as? String, "ldp_vc")
    }

    func test_fetchCredentialConfigurationsSupported_missingBlock_shouldThrow() async {
        let json = """
        {
          "credential_issuer": "https://issuer.com"
        }
        """
        let service = makeService(response: json)

        do {
            _ = try await service.fetchCredentialConfigurationsSupported(from: "https://issuer.com")
            XCTFail("Expected error for missing credential_configurations_supported")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("credential_configurations_supported"))
        }
    }

    func test_fetchCredentialConfigurationsSupported_emptyBlock_shouldThrow() async {
        let json = """
        {
          "credential_configurations_supported": {}
        }
        """
        let service = makeService(response: json)

        do {
            _ = try await service.fetchCredentialConfigurationsSupported(from: "https://issuer.com")
            XCTFail("Expected error for empty credential_configurations_supported")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("empty"))
        }
    }

    func test_fetchCredentialConfigurationsSupported_invalidConfigStructure_shouldThrow() async {
        let json = """
        {
          "credential_configurations_supported": {
            "vc1": "not a dictionary"
          }
        }
        """
        let service = makeService(response: json)

        do {
            _ = try await service.fetchCredentialConfigurationsSupported(from: "https://issuer.com")
            XCTFail("Expected error for invalid configuration format")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Invalid configuration format"))
        }
    }

    func test_fetchCredentialConfigurationsSupported_missingFormat_shouldThrow() async {
        let json = """
        {
          "credential_configurations_supported": {
            "vc1": {
              "scope": "identity"
            }
          }
        }
        """
        let service = makeService(response: json)

        do {
            _ = try await service.fetchCredentialConfigurationsSupported(from: "https://issuer.com")
            XCTFail("Expected error for missing format")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Missing 'format'"))
        }
    }
}
