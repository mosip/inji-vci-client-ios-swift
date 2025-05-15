import Foundation

struct AuthServerMetadata: Codable {
    let issuer: String
    let grantTypesSupported: [String]?
    let tokenEndpoint: String?
    let authorizationEndpoint: String?

    enum CodingKeys: String, CodingKey {
        case issuer
        case grantTypesSupported = "grant_types_supported"
        case tokenEndpoint = "token_endpoint"
        case authorizationEndpoint = "authorization_endpoint"
    }
}

