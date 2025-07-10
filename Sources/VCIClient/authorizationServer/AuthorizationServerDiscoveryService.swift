import Foundation

class AuthorizationServerDiscoveryService {
    func discover(baseUrl: String) async throws -> AuthorizationServerMetadata {
        let oauthUrl = "\(baseUrl)/.well-known/oauth-authorization-server"
        let openidUrl = "\(baseUrl)/.well-known/openid-configuration"
        let timeout = Constants.defaultNetworkTimeoutInMillis

        // Try OAuth discovery
        do {
            let oauthResponse = try await NetworkManager.shared.sendRequest(
                url: oauthUrl,
                method: .get,
                timeoutMillis: timeout
            )

            if !oauthResponse.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let metadata = try JsonUtils.deserialize(oauthResponse.body, as: AuthorizationServerMetadata.self) {
                return metadata
            }
        } catch {
            print("OAuth discovery failed, trying OpenID discovery: \(error.localizedDescription)")
        }

        // Fallback: Try OpenID discovery
        do {
            let openidResponse = try await NetworkManager.shared.sendRequest(
                url: openidUrl,
                method: .get,
                timeoutMillis: timeout
            )

            if !openidResponse.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let metadata = try JsonUtils.deserialize(openidResponse.body, as: AuthorizationServerMetadata.self) {
                return metadata
            }
        } catch {
            print("OpenID discovery also failed: \(error.localizedDescription)")
        }

        throw AutorizationServerDiscoveryException("Failed to discover authorization server metadata at both endpoints.")
    }
}
