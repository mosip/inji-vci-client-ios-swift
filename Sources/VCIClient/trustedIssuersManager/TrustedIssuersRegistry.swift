import Foundation
import Security

final class TrustedIssuerRegistry {
    private let keychainKey = "trusted_issuers_vci"

    func isTrusted(issuer: String) -> Bool {
        return loadTrustedIssuers().contains(issuer)
    }

    func markTrusted(issuer: String) {
        var trustedIssuers = loadTrustedIssuers()
        trustedIssuers.insert(issuer)
        saveTrustedIssuers(trustedIssuers)
    }

    func revokeTrust(issuer: String) {
        var trustedIssuers = loadTrustedIssuers()
        trustedIssuers.remove(issuer)
        saveTrustedIssuers(trustedIssuers)
    }

    func allTrustedIssuers() -> [String] {
        return Array(loadTrustedIssuers())
    }

    private func loadTrustedIssuers() -> Set<String> {
        guard let data = KeychainHelper.load(key: keychainKey),
              let list = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(list)
    }

    private func saveTrustedIssuers(_ issuers: Set<String>) {
        let encoded = try? JSONEncoder().encode(Array(issuers))
        KeychainHelper.save(key: keychainKey, data: encoded)
    }
}
