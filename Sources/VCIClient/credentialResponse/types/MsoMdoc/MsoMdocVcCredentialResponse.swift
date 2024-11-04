import Foundation
struct MsoMdocCredentialResponse : Codable, CredentialResponse {
    var credential: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        credential = try container.decode(String.self, forKey: .credential)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(credential, forKey: .credential)
    }
    
    enum CodingKeys: String, CodingKey {
        case credential
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
