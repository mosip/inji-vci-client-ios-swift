@testable import VCIClient
import XCTest

final class TokenServiceTests: XCTestCase {
    func test_getAccessToken_withPreAuthCode_success() async throws {
        let mockToken = TokenResponse.mock()
        let json = try JSONEncoder().encode(mockToken)
        let mockResponse = String(data: json, encoding: .utf8)!

        let mockNetwork = MockNetworkManager()
        mockNetwork.responseBody = mockResponse

        let service = TokenService(networkManager: mockNetwork)

        let result = try await service.getAccessToken(
            tokenEndpoint: "https://example.com/token",
            preAuthCode: "valid-code"
        )

        XCTAssertEqual(result.accessToken, "mock-access-token")
        XCTAssertEqual(mockNetwork.capturedParams["pre-authorized_code"], "valid-code")
    }

    func test_getAccessToken_withAuthCode_success() async throws {
        let mockToken = TokenResponse.mock()
        let json = try JSONEncoder().encode(mockToken)
        let mockResponse = String(data: json, encoding: .utf8)!
        let mockNetwork = MockNetworkManager()
        mockNetwork.responseBody = mockResponse

        let service = TokenService(networkManager: mockNetwork)

        let result = try await service.getAccessToken(
            tokenEndpoint: "https://example.com/token",
            authCode: "auth123",
            clientId: "clientABC",
            redirectUri: "app://callback",
            codeVerifier: "verifier123"
        )

        XCTAssertEqual(result.accessToken, "mock-access-token")
        XCTAssertEqual(mockNetwork.capturedParams["code"], "auth123")
        XCTAssertEqual(mockNetwork.capturedParams["client_id"], "clientABC")
    }

    func test_preAuthCode_missing_shouldThrow() async {
        let service = TokenService(networkManager: MockNetworkManager())

        do {
            _ = try await service.getAccessToken(
                tokenEndpoint: "https://example.com/token",
                preAuthCode: ""
            )
            XCTFail("Expected exception not thrown")
        } catch let error as DownloadFailedException {
            XCTAssertTrue(error.message.contains("Pre-authorized code is missing"))
        } catch {
            XCTFail("Expected exception not thrown")
        }
    }

    func test_parseTokenResponse_empty_shouldThrow() async {
        let mockNetwork = MockNetworkManager()
        mockNetwork.responseBody = ""

        let service = TokenService(networkManager: mockNetwork)

        do {
            _ = try await service.getAccessToken(
                tokenEndpoint: "https://example.com/token",
                preAuthCode: "code"
            )
            XCTFail("Expected error for empty response body")
        } catch let error as DownloadFailedException {
            XCTAssertTrue(error.message.contains("Token response body is empty"))
        } catch {
            XCTFail("Expected exception not thrown")
        }
    }

    func test_parseTokenResponse_missingAccessToken_shouldThrow() async throws {
        let badJson = """
        {
            "access_token": "",
            "token_type": "Bearer"
        }
        """
        let mockNetwork = MockNetworkManager()
        mockNetwork.responseBody = badJson

        let service = TokenService(networkManager: mockNetwork)

        do {
            _ = try await service.getAccessToken(
                tokenEndpoint: "https://example.com/token",
                preAuthCode: "code"
            )
            XCTFail("Expected InvalidAccessTokenException")
        } catch let error as InvalidAccessTokenException {
            XCTAssertTrue(error.message.contains("Access token missing in token response"))
        } catch {
            XCTFail("Expected InvalidAccessTokenException")
        }
    }

    func test_parseTokenResponse_fullJson_shouldParseCorrectly() async throws {
        let fullJson = """
        {
            "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
            "token_type": "Bearer",
            "expires_in": 3600,
            "c_nonce": "1234567890",
            "c_nonce_expires_in": 45
        }
        """
        let mockNetwork = MockNetworkManager()
        mockNetwork.responseBody = fullJson

        let service = TokenService(networkManager: mockNetwork)

        let result = try await service.getAccessToken(
            tokenEndpoint: "https://example.com/token",
            preAuthCode: "valid-code"
        )

        XCTAssertEqual(result.accessToken, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
        XCTAssertEqual(result.tokenType, "Bearer")
        XCTAssertEqual(result.expiresIn, 3600)
        XCTAssertEqual(result.cNonce, "1234567890")
        XCTAssertEqual(result.cNonceExpiresIn, 45)
    }

    func test_parseTokenResponse_missingOptionalFields_shouldUseDefaults() async throws {
        let minimalJson = """
        {
            "access_token": "abc123",
            "token_type": "Bearer",
            "expires_in": 3000
        }
        """
        let mockNetwork = MockNetworkManager()
        mockNetwork.responseBody = minimalJson

        let service = TokenService(networkManager: mockNetwork)

        let result = try await service.getAccessToken(
            tokenEndpoint: "https://example.com/token",
            preAuthCode: "valid-code"
        )

        XCTAssertEqual(result.accessToken, "abc123")
        XCTAssertEqual(result.tokenType, "Bearer")
        XCTAssertEqual(result.expiresIn, 3000)
        XCTAssertEqual(result.cNonce, nil)
        XCTAssertEqual(result.cNonceExpiresIn, nil)
    }
}
