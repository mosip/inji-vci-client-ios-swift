import Foundation

class IssuerMetadataService {
    private let session: NetworkManager
    private let timeoutMillis: Int64
    private var cachedRawMetadata: [String: [String: Any]] = [:]

    init(session: NetworkManager = NetworkManager.shared, timeoutMillis: Int64 = 10000) {
        self.session = session
        self.timeoutMillis = timeoutMillis
    }

    func fetchIssuerMetadataResult(
        credentialIssuer: String,
        credentialConfigurationId: String
    ) async throws -> IssuerMetadataResult {
        let rawIssuerMetadata: [String: Any]

        if let cached = cachedRawMetadata[credentialIssuer] {
            rawIssuerMetadata = cached
        } else {
            let fetched = try await fetchAndParseIssuerMetadata(from: credentialIssuer)
            cachedRawMetadata[credentialIssuer] = fetched
            rawIssuerMetadata = fetched
        }

        let resolvedIssuerMetadata = try resolveMetadata(
            credentialConfigurationId: credentialConfigurationId,
            rawIssuerMetadata: rawIssuerMetadata
        )

        return IssuerMetadataResult(
            issuerMetadata: resolvedIssuerMetadata,
            raw: rawIssuerMetadata,
            credentialIssuer: credentialIssuer
        )
    }

    func fetchAndParseIssuerMetadata(from credentialIssuer: String) async throws -> [String: Any] {
        let wellKnownUrl = credentialIssuer + Constants.credentialIssuerWellknownUriSuffix
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

        return jsonObject
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

        let scope = credentialType["scope"] as? String ?? "openid"

        switch format {
        case .mso_mdoc:
            guard let doctype = credentialType["doctype"] as? String else {
                throw IssuerMetadataFetchException("Missing doctype")
            }

            let claims = credentialType["claims"] as? [String: Any]
            return IssuerMetadata(
                credentialIssuer: credentialIssuer,
                credentialEndpoint: credentialEndpoint,
                credentialFormat: .mso_mdoc,
                doctype: doctype,
                claims: claims?.mapValues { AnyCodable($0) },
                authorizationServers: rawIssuerMetadata["authorization_servers"] as? [String],
                scope: scope
            )

        case .ldp_vc:
            let definition = credentialType["credential_definition"] as? [String: Any] ?? [:]
            let types = definition["type"] as? [String]
            let context = definition["@context"] as? [String]
            return IssuerMetadata(
                credentialIssuer: credentialIssuer,
                credentialEndpoint: credentialEndpoint,
                credentialType: types,
                context: context,
                credentialFormat: .ldp_vc,
                authorizationServers: rawIssuerMetadata["authorization_servers"] as? [String],
                scope: scope
            )

        case .vc_sd_jwt:
            guard let vct = credentialType["vct"] as? String else {
                throw IssuerMetadataFetchException("Missing vct in sd_jwt_vc configuration")
            }

            let claims = credentialType["claims"] as? [String: Any]
            return IssuerMetadata(
                credentialIssuer: credentialIssuer,
                credentialEndpoint: credentialEndpoint,
                credentialFormat: .vc_sd_jwt,
                claims: claims?.mapValues { AnyCodable($0) },
                authorizationServers: rawIssuerMetadata["authorization_servers"] as? [String],
                vct: vct,
                scope: scope
            )
        }
    }
}
