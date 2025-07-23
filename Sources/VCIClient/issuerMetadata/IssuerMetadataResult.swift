import Foundation

struct IssuerMetadataResult {
    var issuerMetadata: IssuerMetadata
    let raw: [String: Any?]
    let credentialIssuer: String?

    init(issuerMetadata: IssuerMetadata, raw: [String: Any?], credentialIssuer: String? = nil) {
        self.issuerMetadata = issuerMetadata
        self.raw = raw
        self.credentialIssuer = credentialIssuer
    }
    
    func extractJwtProofSigningAlgorithms(
        credentialConfigurationId: String
    ) -> [String] {
        guard
            let configurations = raw["credential_configurations_supported"] as? [String: Any],
            let config = configurations[credentialConfigurationId] as? [String: Any],
            let proofTypes = config["proof_types_supported"] as? [String: Any],
            let jwt = proofTypes["jwt"] as? [String: Any],
            let algos = jwt["proof_signing_alg_values_supported"] as? [String]
        else {
            return []
        }

        return algos
    }
    
}
