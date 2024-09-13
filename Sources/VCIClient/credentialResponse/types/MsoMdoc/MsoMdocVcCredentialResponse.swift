import Foundation
struct MsoMdocCredential: Encodable, CredentialResponse {
    var credential: [String: AnyCodable]
    
    init(credential credentialData: [String:AnyCodable]){
        credential = credentialData
    }
    
    enum CodingKeys: String, CodingKey {
        case credential
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(credential, forKey: .credential)
    }
    
    func toJSONString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw DownloadFailedError.encodingResponseFailed
        }
        return jsonString
    } 
}
