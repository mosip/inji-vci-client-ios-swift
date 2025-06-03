import Foundation

enum JsonUtils {
    static func serialize<T: Encodable>(_ object: T) -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.withoutEscapingSlashes]
        do {
            let data = try encoder.encode(object)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{}"
        }
    }

    static func deserialize<T: Decodable>(_ json: String, as type: T.Type) throws -> T? {
        guard !json.isEmpty, let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()

        return try decoder.decode(T.self, from: data)
    }

    static func toMap(_ json: String) -> [String: Any] {
        guard !json.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let data = json.data(using: .utf8) else {
            return [:]
        }

        do {
            let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
            return jsonObj as? [String: Any] ?? [:]
        } catch {
            return [:]
        }
    }
}
