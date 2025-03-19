import Foundation


public struct CredentialResponse: Codable {
    let credential: AnyCodable

    public func toJsonString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw DownloadFailedError.encodingResponseFailed
        }
        return jsonString
    }
}

public struct AnyCodable: Codable {
    var value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let logTag = Util.getLogTag(className: String(describing: type(of: self)))
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
            print(logTag,"Error occured while decoding response")
            throw DownloadFailedError.decodingResponseFailed
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        let logTag = Util.getLogTag(className: String(describing: type(of: self)))
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
            print(logTag,"Error occured while encoding response")
            throw DownloadFailedError.encodingResponseFailed
        }
    }
}
