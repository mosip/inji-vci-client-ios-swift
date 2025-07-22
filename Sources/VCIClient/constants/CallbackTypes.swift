public typealias AuthorizeUserCallback = (_ authorizationUrl: String) async throws -> String
public typealias TokenResponseCallback = (_ tokenRequest: TokenRequest) async throws -> TokenResponse
public typealias ProofJwtCallback = (
    _ credentialIssuer: String,
    _ cNonce: String?,
    _ proofSigningAlgorithmsSupported: [String]
) async throws -> String
public typealias CheckIssuerTrustCallback = ((_ credentialIssuer: String, _ issuerDisplay: [[String: Any]]) async throws -> Bool)?
public typealias TxCodeCallback = ((_ inputMode: String?, _ description: String?, _ length: Int?) async throws -> String)?
