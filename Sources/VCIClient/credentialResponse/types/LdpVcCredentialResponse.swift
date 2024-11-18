import Foundation

struct AnyCodable: Codable {
    var value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let nestedDict = try? container.decode([String: AnyCodable].self) {
            value = nestedDict.mapValues { $0.value }
        } else if let nestedArray = try? container.decode([AnyCodable].self) {
            value = nestedArray.map { $0.value }
        } else if container.decodeNil() {
            value = Optional<Any>.none as Any
        } else {
            throw DownloadFailedError.decodingResponseFailed
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let nestedDict = value as? [String: Any] {
            try container.encode(nestedDict.mapValues { AnyCodable($0) })
        } else if let nestedArray = value as? [Any] {
            try container.encode(nestedArray.map { AnyCodable($0) })
        } else if value is Optional<Any> {
            try container.encodeNil()
        } else {
            throw DownloadFailedError.encodingResponseFailed
        }
    }
}

struct VC: Codable, CredentialResponse {
    var credential: [String: AnyCodable]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        credential = try container.decode([String: AnyCodable].self, forKey: .credential)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(credential, forKey: .credential)
    }
    
    enum CodingKeys: String, CodingKey {
        case format
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
