import XCTest
@testable import VCIClient

final class CredentialOfferServiceTests: XCTestCase {

    var mockSession: MockNetworkSession!
    var service: CredentialOfferService!

    override func setUp() {
        super.setUp()
        mockSession = MockNetworkSession()
        service = CredentialOfferService(session: mockSession)
    }

    override func tearDown() {
        mockSession = nil
        service = nil
        super.tearDown()
    }

    func testHandleByValueOffer_Success() throws {
        let validJson = """
        {
            "credential_issuer": "https://issuer.example.com",
            "credential_configuration_ids": ["UniversityDegreeCredential"]
        }
        """.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        let offer = try service.handleByValueOffer(encodedOffer: validJson)
        XCTAssertEqual(offer.credentialIssuer, "https://issuer.example.com")
    }

    func testHandleByReferenceOffer_Success() async throws {
        let responseJson = """
        {
            "credential_issuer": "https://issuer.example.com",
            "credential_configuration_ids": ["UniversityDegreeCredential"]
        }
        """.data(using: .utf8)!

        mockSession.data = responseJson
        mockSession.response = HTTPURLResponse(url: URL(string: "https://issuer.example.com")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)

        let offer = try await service.handleByReferenceOffer(from: "https://issuer.example.com")
        XCTAssertEqual(offer.credentialIssuer, "https://issuer.example.com")
    }

    func testHandleByReferenceOffer_ThrowsForEmptyData() async {
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "https://issuer.example.com")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)

        do {
            _ = try await service.handleByReferenceOffer(from: "https://issuer.example.com")
            XCTFail("Expected emptyResponse error but got success")
        } catch let error as CredentialOfferError {
            XCTAssertEqual(error, .emptyResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testHandleByReferenceOffer_ThrowsForInvalidURL() async {
        do {
            _ = try await service.handleByReferenceOffer(from: "invalid-url")
            XCTFail("Expected fetchFailed error for invalid URL")
        } catch let error as CredentialOfferError {
            XCTAssertEqual(error, .fetchFailed("Invalid URL"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

}
