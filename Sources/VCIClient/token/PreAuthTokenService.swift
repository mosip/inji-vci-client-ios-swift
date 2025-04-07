import Foundation

public struct PreAuthTokenService {
    
    public init() {}
    
    public func exchangePreAuthCodeForToken(
        issuerMetaData: IssuerMeta,
        txCode: String?,
        session: NetworkSession = URLSession.shared
    ) async throws -> TokenResponse {
        
        guard let preAuthCode = issuerMetaData.preAuthorizedCode, !preAuthCode.isEmpty else {
            throw TokenExchangeError.missingPreAuthCode
        }
        
        guard let tokenEndpoint = issuerMetaData.tokenEndpoint, let url = URL(string: tokenEndpoint) else {
            throw TokenExchangeError.missingTokenEndpoint
        }
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "urn:ietf:params:oauth:grant-type:pre-authorized_code"),
            URLQueryItem(name: "pre-authorized_code", value: preAuthCode)
        ]
        
        if let txCode = txCode, !txCode.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "tx_code", value: txCode))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)

        return try parseTokenResponse(from: data)
    }
    
    private func parseTokenResponse(from data: Data) throws -> TokenResponse {
        guard !data.isEmpty else {
            throw TokenExchangeError.emptyResponse
        }
        
        let decoder = JSONDecoder()
        let token = try decoder.decode(TokenResponse.self, from: data)
        
        guard !token.accessToken.isEmpty else {
            throw TokenExchangeError.missingAccessToken
        }
        
        return token
    }
}
