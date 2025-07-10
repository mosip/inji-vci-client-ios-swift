import Foundation

public struct IssuerMetadata : Codable{
    public let credentialIssuer: String
    public let credentialEndpoint: String
    public let credentialType: [String]?
    public let context: [String]?
    public let credentialFormat: CredentialFormat
    public let doctype: String?
    public let claims: [String: AnyCodable]?
    public let authorizationServers: [String]?
    public var tokenEndpoint: String?
    public let scope: String?

    public init(
        credentialIssuer: String,
        credentialEndpoint: String,
        credentialType: [String]? = nil,
        context: [String]? = nil,
        credentialFormat: CredentialFormat,
        doctype: String? = nil,
        claims: [String: AnyCodable]? = nil,
        authorizationServers: [String]? = nil,
        tokenEndpoint: String? = nil,
        scope: String = "openId"
    ) {
        self.credentialIssuer = credentialIssuer
        self.credentialEndpoint = credentialEndpoint
        self.credentialType = credentialType
        self.context = context
        self.credentialFormat = credentialFormat
        self.doctype = doctype
        self.claims = claims
        self.authorizationServers = authorizationServers
        self.tokenEndpoint = tokenEndpoint
        self.scope = scope
    }
}
