
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
}
