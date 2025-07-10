public typealias AuthorizeUserCallback = (_ authorizationUrl: String) async throws -> String
public typealias TokenresponseCallback = (_ tokenRequest: TokenRequest) async throws -> TokenResponse
public typealias ProofJwtCallback = (
    _ credentialIssuer: String,
    _ cNonce: String?,
    _ proofSigningAlgorithmsSupported: [String]
) async throws -> String
public typealias CheckIssuerTrustCallback = ((_ credentialIssuer: String, _ issuerDisplay: [[String: Any]]) async throws -> Bool)?
