public struct ClientMetadata: Codable {
    public let clientId: String
    public let redirectUri: String

    public init(clientId: String, redirectUri: String) {
        self.clientId = clientId
        self.redirectUri = redirectUri
    }
}
