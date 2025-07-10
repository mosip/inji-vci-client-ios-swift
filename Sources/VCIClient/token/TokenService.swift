import Foundation

class TokenService {
    let networkManager: NetworkManager
    init(networkManager: NetworkManager? = nil) {
        self.networkManager = networkManager ?? NetworkManager.shared
    }

    func getAccessToken(
        getTokenResponse: @escaping TokenResponseCallback,
        tokenEndpoint: String,
        timeoutMillis: Int64 = Constants.defaultNetworkTimeoutInMillis,
        preAuthCode: String,
        txCode: String? = nil
    ) async throws -> TokenResponse {
        return try await obtainAccessToken(
            grantType: .preAuthorized,
            getTokenResponse: getTokenResponse,
            tokenEndpoint: tokenEndpoint,
            timeoutMillis: timeoutMillis,
            preAuthCode: preAuthCode,
            txCode: txCode
        )
    }

    func getAccessToken(
        getTokenResponse: @escaping TokenResponseCallback,
        tokenEndpoint: String,
        timeoutMillis: Int64 = Constants.defaultNetworkTimeoutInMillis,
        authCode: String,
        clientId: String? = nil,
        redirectUri: String? = nil,
        codeVerifier: String? = nil
    ) async throws -> TokenResponse {
        return try await obtainAccessToken(
            grantType: .authorizationCode,
            getTokenResponse: getTokenResponse,
            tokenEndpoint: tokenEndpoint,
            timeoutMillis: timeoutMillis,
            authCode: authCode,
            clientId: clientId,
            redirectUri: redirectUri,
            codeVerifier: codeVerifier
        )
    }
    
    private func obtainAccessToken(
        grantType: GrantType,
        getTokenResponse: @escaping TokenResponseCallback,
        tokenEndpoint: String,
        timeoutMillis: Int64,
        preAuthCode: String? = nil,
        txCode: String? = nil,
        authCode: String? = nil,
        clientId: String? = nil,
        redirectUri: String? = nil,
        codeVerifier: String? = nil
    ) async throws -> TokenResponse {
        let tokenRequest = TokenRequest(
            grantType: grantType,
            tokenEndpoint: tokenEndpoint,
            authCode: authCode,
            preAuthCode: preAuthCode,
            txCode: txCode,
            clientId: clientId,
            redirectUri: redirectUri,
            codeVerifier: codeVerifier
        )

        return try await getTokenResponse(tokenRequest)
    }
}
