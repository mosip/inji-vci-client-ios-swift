import Foundation

class TokenService {
    let networkManager: NetworkManager
    init(networkManager: NetworkManager? = nil) {
        self.networkManager = networkManager ?? NetworkManager.shared
    }

    func getAccessToken(
        tokenEndpoint: String,
        timeoutMillis: Int64 = Constants.defaultNetworkTimeoutInMillis,
        preAuthCode: String,
        txCode: String? = nil
    ) async throws -> TokenResponse {
        return try await fetchAccessToken(
            grantType: .preAuthorized,
            tokenEndpoint: tokenEndpoint,
            timeoutMillis: timeoutMillis,
            preAuthCode: preAuthCode,
            txCode: txCode
        )
    }

    func getAccessToken(
        tokenEndpoint: String,
        timeoutMillis: Int64 = Constants.defaultNetworkTimeoutInMillis,
        authCode: String,
        clientId: String? = nil,
        redirectUri: String? = nil,
        codeVerifier: String? = nil
    ) async throws -> TokenResponse {
        return try await fetchAccessToken(
            grantType: .authorizationCode,
            tokenEndpoint: tokenEndpoint,
            timeoutMillis: timeoutMillis,
            authCode: authCode,
            clientId: clientId,
            redirectUri: redirectUri,
            codeVerifier: codeVerifier
        )
    }

    private func fetchAccessToken(
        grantType: GrantType,
        tokenEndpoint: String,
        timeoutMillis: Int64,
        preAuthCode: String? = nil,
        txCode: String? = nil,
        authCode: String? = nil,
        clientId: String? = nil,
        redirectUri: String? = nil,
        codeVerifier: String? = nil
    ) async throws -> TokenResponse {
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded",
        ]
        let bodyParams = try buildBodyParams(
            grantType: grantType,
            preAuthCode: preAuthCode,
            txCode: txCode,
            authCode: authCode,
            clientId: clientId,
            redirectUri: redirectUri,
            codeVerifier: codeVerifier
        )

        let response = try await networkManager.sendRequest(
            url: tokenEndpoint,
            method: .post,
            headers: headers,
            bodyParams: bodyParams,
            timeoutMillis: timeoutMillis
        )

        return try parseTokenResponse(responseBody: response.body)
    }

    private func buildBodyParams(
        grantType: GrantType,
        preAuthCode: String?,
        txCode: String?,
        authCode: String?,
        clientId: String?,
        redirectUri: String?,
        codeVerifier: String?
    ) throws -> [String: String] {
        switch grantType {
        case .preAuthorized:
            guard let code = preAuthCode, !code.isEmpty else {
                throw DownloadFailedException("Pre-authorized code is missing.")
            }
            var params = [
                "grant_type": grantType.rawValue,
                "pre-authorized_code": code,
            ]
            if let txCode = txCode {
                params["tx_code"] = txCode
            }
            return params

        case .authorizationCode:
            guard let code = authCode, !code.isEmpty else {
                throw DownloadFailedException("Authorization code is missing.")
            }
            var params = [
                "grant_type": grantType.rawValue,
                "code": code,
            ]
            if let clientId = clientId { params["client_id"] = clientId }
            if let redirectUri = redirectUri { params["redirect_uri"] = redirectUri }
            if let codeVerifier = codeVerifier { params["code_verifier"] = codeVerifier }
            return params

        default:
            throw DownloadFailedException("Unknown grant type")
        }
    }

    private func parseTokenResponse(responseBody: String) throws -> TokenResponse {
        guard !responseBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DownloadFailedException("Token response body is empty")
        }

        guard let tokenResponse = try JsonUtils.deserialize(responseBody, as: TokenResponse.self) else {
            throw InvalidAccessTokenException("Failed to parse token response")
        }

        guard !tokenResponse.accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw InvalidAccessTokenException("Access token missing in token response")
        }

        return tokenResponse
    }
}
