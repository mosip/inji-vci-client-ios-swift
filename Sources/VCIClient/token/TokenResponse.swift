public struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int?
    let cNonce: String?
    let cNonceExpiresIn: Int?
    
    public init(
            accessToken: String,
            tokenType: String,
            expiresIn: Int? = nil,
            cNonce: String = "",
            cNonceExpiresIn: Int = 0
        ) {
            self.accessToken = accessToken
            self.tokenType = tokenType
            self.expiresIn = expiresIn
            self.cNonce = cNonce
            self.cNonceExpiresIn = cNonceExpiresIn
        }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case cNonce = "c_nonce"
        case cNonceExpiresIn = "c_nonce_expires_in"
    }
}
