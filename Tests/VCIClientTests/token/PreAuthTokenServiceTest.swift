
import XCTest
@testable import VCIClient

final class PreAuthTokenServiceTest: XCTestCase {
    
    var service: PreAuthTokenService!
    var mockSession: MockNetworkSession!
    
    override func setUp() {
        super.setUp()
        service = PreAuthTokenService()
        mockSession = MockNetworkSession()
    }
    
    override func tearDown() {
        service = nil
        mockSession = nil
        super.tearDown()
    }
    
    func testExchangePreAuthCodeForToken_success() async throws {
        let tokenJSON = """
        {
            "access_token": "sample_token",
            "token_type": "Bearer",
            "expires_in": 3600,
            "c_nonce": "some-nonce",
            "c_nonce_expires_in": 600
        }
        """.data(using: .utf8)!
        
        mockSession.data = tokenJSON
        mockSession.response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)
        
        let meta = IssuerMeta(
            credentialAudience: "https://aud.example.com",
            credentialEndpoint: "https://example.com/credential",
            downloadTimeoutInMilliseconds: 3000,
            credentialType: ["VerifiableCredential"],
            credentialFormat: .ldp_vc,
            preAuthorizedCode: "pre-code",
            tokenEndpoint: "https://example.com/token"
        )
        
        let token = try await service.exchangePreAuthCodeForToken(issuerMetaData: meta, txCode: nil, session: mockSession)
        XCTAssertEqual(token.accessToken, "sample_token")
        XCTAssertEqual(token.cNonce, "some-nonce")
    }
    
    func testExchangePreAuthCodeForToken_throwsWhenPreAuthCodeMissing() async {
        let meta = IssuerMeta(
            credentialAudience: "aud",
            credentialEndpoint: "url",
            downloadTimeoutInMilliseconds: 3000,
            credentialType: ["VC"],
            credentialFormat: .ldp_vc,
            preAuthorizedCode: nil,
            tokenEndpoint: "https://example.com/token"
        )
        
        do {
            _ = try await service.exchangePreAuthCodeForToken(issuerMetaData: meta, txCode: nil, session: mockSession)
            XCTFail("Expected error was not thrown")
        } catch let error as TokenExchangeError {
            XCTAssertEqual(error, .missingPreAuthCode)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testExchangePreAuthCodeForToken_throwsWhenTokenEndpointMissing() async {
        let meta = IssuerMeta(
            credentialAudience: "aud",
            credentialEndpoint: "url",
            downloadTimeoutInMilliseconds: 3000,
            credentialType: ["VC"],
            credentialFormat: .ldp_vc,
            preAuthorizedCode: "code",
            tokenEndpoint: nil
        )
        
        do {
            _ = try await service.exchangePreAuthCodeForToken(issuerMetaData: meta, txCode: nil, session: mockSession)
            XCTFail("Expected error was not thrown")
        } catch let error as TokenExchangeError {
            XCTAssertEqual(error, .missingTokenEndpoint)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    
    func testExchangePreAuthCodeForToken_throwsWhenResponseIsEmpty() async {
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)
        
        let meta = IssuerMeta(
            credentialAudience: "aud",
            credentialEndpoint: "url",
            downloadTimeoutInMilliseconds: 3000,
            credentialType: ["VC"],
            credentialFormat: .ldp_vc,
            preAuthorizedCode: "code",
            tokenEndpoint: "https://example.com/token"
        )
        
        do {
            _ = try await service.exchangePreAuthCodeForToken(issuerMetaData: meta, txCode: nil, session: mockSession)
            XCTFail("Expected error was not thrown")
        } catch let error as TokenExchangeError {
            XCTAssertEqual(error, .emptyResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    
    func testExchangePreAuthCodeForToken_throwsWhenAccessTokenMissing() async {
        let tokenJSON = """
        {
            "token_type": "Bearer",
            "access_token": "",s
            "expires_in": 3600
        }
        """.data(using: .utf8)!
        
        mockSession.data = tokenJSON
        mockSession.response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)
        
        let meta = IssuerMeta(
            credentialAudience: "aud",
            credentialEndpoint: "url",
            downloadTimeoutInMilliseconds: 3000,
            credentialType: ["VC"],
            credentialFormat: .ldp_vc,
            preAuthorizedCode: "code",
            tokenEndpoint: "https://example.com/token"
        )
        
        do {
            _ = try await service.exchangePreAuthCodeForToken(issuerMetaData: meta, txCode: nil, session: mockSession)
            XCTFail("Expected error was not thrown")
        } catch let error as TokenExchangeError {
            XCTAssertEqual(error, .missingAccessToken)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
}

