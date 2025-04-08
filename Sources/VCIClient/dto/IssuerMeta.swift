import Foundation

public struct IssuerMeta {
    public let credentialAudience: String
    public let credentialEndpoint: String
    public let downloadTimeoutInMilliseconds: Int
    public let credentialType: [String]?
    public let credentialFormat: CredentialFormat
    public let context: [String]?
    public let docType: String?
    public let claims: [String: Any]?
    public let preAuthorizedCode: String?
    public let tokenEndpoint: String?
    
    public init(credentialAudience: String,
                credentialEndpoint: String,
                downloadTimeoutInMilliseconds: Int,
                credentialType: [String]? = nil,
                credentialFormat: CredentialFormat,
                docType: String? = nil,
                claims: [String: Any]? = nil,
                preAuthorizedCode: String? = nil,
                tokenEndpoint:String? = nil,
                context: [String]? = nil
    ) {
        
        self.credentialAudience = credentialAudience
        self.credentialEndpoint = credentialEndpoint
        self.downloadTimeoutInMilliseconds = downloadTimeoutInMilliseconds
        self.credentialType = credentialType
        self.credentialFormat = credentialFormat
        self.context = context
        self.docType = docType
        self.claims = claims
        self.preAuthorizedCode = preAuthorizedCode
        self.tokenEndpoint = tokenEndpoint
    }
}
