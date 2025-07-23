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
            getTokenResponse: {_ in TokenResponse(accessToken: "mock-token", tokenType: "Bearer")}, tokenEndpoint: "https://example.com/token",
            preAuthCode: "valid-code"
        )

        XCTAssertEqual(result.accessToken, "mock-token")
       
    }

    func test_getAccessToken_withAuthCode_success() async throws {
        let mockToken = TokenResponse.mock()
        let json = try JSONEncoder().encode(mockToken)
        let mockResponse = String(data: json, encoding: .utf8)!
        let mockNetwork = MockNetworkManager()
        mockNetwork.responseBody = mockResponse

        let service = TokenService(networkManager: mockNetwork)

        let result = try await service.getAccessToken(
            getTokenResponse: {_ in TokenResponse(accessToken: "mock-token", tokenType: "Bearer")}, tokenEndpoint: "https://example.com/token",
            authCode: "auth123",
            clientId: "clientABC",
            redirectUri: "app://callback",
            codeVerifier: "verifier123"
        )

        XCTAssertEqual(result.accessToken, "mock-token")
    }

}
