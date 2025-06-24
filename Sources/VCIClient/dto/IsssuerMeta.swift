import Foundation

@available(*, deprecated, message: "Use IssuerMetadata instead as per the new VCIClient library contract.")
public struct IssuerMeta {
    public let credentialAudience: String
    public let credentialEndpoint: String
    public let downloadTimeoutInMilliseconds: Int
    public let credentialType: [String]?
    public let credentialFormat: CredentialFormat
    public let docType: String?
    public let claims: [String: Any]?

    public init(credentialAudience: String,
                credentialEndpoint: String,
                downloadTimeoutInMilliseconds: Int,
                credentialType: [String]? = nil,
                credentialFormat: CredentialFormat,
                docType: String? = nil,
                claims: [String: Any]? = nil) {
        self.credentialAudience = credentialAudience
        self.credentialEndpoint = credentialEndpoint
        self.downloadTimeoutInMilliseconds = downloadTimeoutInMilliseconds
        self.credentialType = credentialType
        self.credentialFormat = credentialFormat
        self.docType = docType
        self.claims = claims
    }
}
