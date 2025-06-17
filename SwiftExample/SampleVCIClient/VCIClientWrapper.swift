import Foundation
import Sodium
import VCIClient

class VCIClientWrapper {
    static let shared = VCIClientWrapper()
    private let sodium = Sodium()

    private init() {}

    func startCredentialOfferFlow(from scanned: String, onResult: @escaping (String) -> Void) {
        Task {
            do {
                let client = VCIClient(traceabilityId: "demo-trace-id")

                let credentialResponse = try await client.requestCredentialByCredentialOffer(
                    credentialOffer: scanned,
                    clientMetadata: ClientMetaData(clientId: "wallet", redirectUri: "https://sampleApp"),
                    getTxCode: nil,
                    getProofJwt: { accessToken, cNonce, issuerMetadata, configId in
                        self.signProofJWT(
                            accessToken: accessToken,
                            cNonce: cNonce,
                            issuer: issuerMetadata?["credential_issuer"] as? String ?? "https://default-issuer",
                            credentialConfigurationId: configId, isTrustedIssuer: false
                        )
                    },
                    getAuthCode: { _ in
                        // Replace with actual navigation and capture flow
                        "dummy-auth-code"
                    }
                )

                if let vc = try credentialResponse?.toJsonString() {
                    onResult("✅ Credential Issued:\n\(vc)")
                } else {
                    onResult("❌ No credential received")
                }
            } catch {
                onResult("❌ Error: \(error.localizedDescription)")
            }
        }
    }

    func startTrustedIssuerFlow(from uri: String, onResult: @escaping (String) -> Void) {
        Task {
            do {
                let client = VCIClient(traceabilityId: "demo-trace-id")

                let issuerMetadata = IssuerMetadata(
                    credentialAudience: "https://injicertify-mock.released.mosip.net",
                    credentialEndpoint: "https://injicertify-mock.released.mosip.net/v1/certify/issuance/credential",
                    credentialType: ["VerifiableCredential", "MockVerifiableCredential"],
                    credentialFormat: CredentialFormat.ldp_vc,
                    authorizationServers: ["https://esignet-mock.released.mosip.net"],
                    tokenEndpoint: "https://api.released.mosip.net/v1/mimoto/get-token/Mock",
                    scope: "mock_identity_vc_ldp"
                )

                let credentialResponse = try await client.requestCredentialFromTrustedIssuer(
                    issuerMetadata: issuerMetadata,
                    clientMetadata: ClientMetaData(clientId: "mpartner-default-mimoto-mock-oidc", redirectUri: "io.mosip.residentapp.inji://oauthredirect"),
                    getProofJwt: { accessToken, cNonce, issuerMetadata, configId in
                        self.signProofJWT(
                            accessToken: accessToken,
                            cNonce: cNonce,
                            issuer:"https://injicertify-mock.released.mosip.net",
                            credentialConfigurationId: configId,
                            isTrustedIssuer: true
                        )
                    },
                    getAuthCode: { authEndpoint in
                        return await withCheckedContinuation { continuation in
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: Notification.Name("ShowAuthWebView"), object: authEndpoint)
                            }

                            var observer: NSObjectProtocol?
                            observer = NotificationCenter.default.addObserver(forName: Notification.Name("AuthCodeReceived"), object: nil, queue: .main) { notification in
                                if let code = notification.object as? String {
                                    if let obs = observer {
                                        NotificationCenter.default.removeObserver(obs)
                                    }

                                    continuation.resume(returning: code)
                                }
                            }
                        }
                    }
                )

                if let vc = try credentialResponse?.toJsonString() {
                    onResult("✅ Credential Issued:\n\(vc)")
                } else {
                    onResult("Downloading VC")
                }
            } catch {
               
            }
        }
    }

    private func signProofJWT(accessToken: String, cNonce: String?, issuer: String, credentialConfigurationId: String?, isTrustedIssuer: Bool?) -> String {
        guard let keyPair = sodium.sign.keyPair() else {
            fatalError("❌ Failed to generate Ed25519 key pair")
        }

        let publicKeyJwk: [String: Any] = [
            "kty": "OKP",
            "crv": "Ed25519",
            "x": Data(keyPair.publicKey).base64URLEncodedString(),
        ]

        let publicKeyJwkData = try! JSONSerialization.data(withJSONObject: publicKeyJwk)
        let kid = "did:jwk:" + publicKeyJwkData.base64URLEncodedString() + "#0"
        let alg = isTrustedIssuer == true ? "Ed25519" : "EdDSA"
        let header: [String: Any] = [
            "alg": alg,
            "typ": "openid4vci-proof+jwt",
            "kid": kid,
        ]

        var nonceToUse = cNonce ?? ""
            if nonceToUse.isEmpty {
                let parts = accessToken.split(separator: ".")
                if parts.count >= 2,
                   let payloadData = Data(base64Encoded: String(parts[1])),
                   let payloadJson = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
                   let fallbackNonce = payloadJson["c_nonce"] as? String {
                    nonceToUse = fallbackNonce
                }
            }
            let now = Int(Date().timeIntervalSince1970)

            let payload: [String: Any] = [
                "aud": issuer,
                "nonce": nonceToUse,
                "iat": now,
                "exp": now + 18000
            ]

        let headerData = try! JSONSerialization.data(withJSONObject: header)
        let payloadData = try! JSONSerialization.data(withJSONObject: payload)

        let headerBase64 = headerData.base64URLEncodedString()
        let payloadBase64 = payloadData.base64URLEncodedString()

        let signingInput = "\(headerBase64).\(payloadBase64)"
        let signingBytes = Array(signingInput.utf8)

        guard let signature = sodium.sign.signature(message: signingBytes, secretKey: keyPair.secretKey) else {
            fatalError("❌ Failed to sign JWT")
        }

        let signatureBase64 = Data(signature).base64URLEncodedString()
        return "\(signingInput).\(signatureBase64)"
    }
}

extension Data {
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension Array where Element == UInt8 {
    var data: Data { return Data(self) }
}
