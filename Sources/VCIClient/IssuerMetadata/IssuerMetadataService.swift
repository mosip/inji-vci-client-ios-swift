import Foundation

final class IssuerMetadataService {
    private let session: NetworkManager
    private let timeoutMillis: Int64

    init(session: NetworkManager = NetworkManager.shared, timeoutMillis: Int64 = 10000) {
        self.session = session
        self.timeoutMillis = timeoutMillis
    }

    func fetch(issuerUrl: String, credentialConfigurationId: String) async throws -> IssuerMetadataResult {
        let wellKnownUrl = issuerUrl + "/.well-known/openid-credential-issuer"

        do {
            let response = try await session.sendRequest(
                url: wellKnownUrl,
                method: .get,
                headers: ["Accept": "application/json"],
                timeoutMillis: timeoutMillis
            )

            guard !response.body.isEmpty else {
                throw IssuerMetadataFetchException("Issuer metadata response is empty.")
            }

            guard let data = response.body.data(using: .utf8),
                  let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw IssuerMetadataFetchException("Issuer metadata is not valid JSON.")
            }

            let resolved = try resolveMetadata(
                credentialConfigurationId: credentialConfigurationId,
                rawIssuerMetadata: jsonObject
            )

            return IssuerMetadataResult(
                issuerMetadata: resolved,
                raw: jsonObject
            )
        } catch let e as IssuerMetadataFetchException {
            throw e
        } catch {
            throw IssuerMetadataFetchException("Failed to fetch issuer metadata: \(error.localizedDescription)")
        }
    }

    private func resolveMetadata(credentialConfigurationId: String, rawIssuerMetadata: [String: Any]) throws -> IssuerMetadata {
        guard let configurations = rawIssuerMetadata["credential_configurations_supported"] as? [String: Any],
              let credentialType = configurations[credentialConfigurationId] as? [String: Any] else {
            throw IssuerMetadataFetchException("Missing or invalid credential configuration")
        }

        guard let credentialEndpoint = rawIssuerMetadata["credential_endpoint"] as? String else {
            throw IssuerMetadataFetchException("Missing credential_endpoint")
        }

        guard let credentialIssuer = rawIssuerMetadata["credential_issuer"] as? String else {
            throw IssuerMetadataFetchException("Missing credential_issuer")
        }

        let formatString = credentialType["format"] as? String
        guard let format = CredentialFormat(rawValue: formatString ?? "") else {
            throw IssuerMetadataFetchException("Unsupported or missing credential format")
        }

        switch format {
        case .mso_mdoc:
            guard let doctype = credentialType["doctype"] as? String else {
                throw IssuerMetadataFetchException("Missing doctype")
            }
            let claims = credentialType["claims"] as? [String: Any]
            return IssuerMetadata(
                credentialAudience: credentialIssuer,
                credentialEndpoint: credentialEndpoint,
                credentialFormat: .mso_mdoc,
                doctype: doctype,
                claims: claims?.mapValues { AnyCodable($0) },
                authorizationServers: rawIssuerMetadata["authorization_servers"] as? [String]
            )

        case .ldp_vc:
            let definition = credentialType["credential_definition"] as? [String: Any] ?? [:]
            let types = definition["type"] as? [String]
            let context = definition["@context"] as? [String]
            let scope = credentialType["scope"] as? String
            return IssuerMetadata(
                credentialAudience: credentialIssuer,
                credentialEndpoint: credentialEndpoint,
                credentialType: types,
                context: context,
                credentialFormat: .ldp_vc,
                authorizationServers: rawIssuerMetadata["authorization_servers"] as? [String],
                scope: "openid \(scope ?? "")"
            )
        }
    }
}
