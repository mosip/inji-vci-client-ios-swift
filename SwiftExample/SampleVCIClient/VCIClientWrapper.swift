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
                    clientMetadata: ClientMetadata(clientId: "wallet", redirectUri: "https://sampleApp"),
                    getTxCode: nil,
                    authorizeUser: { _ in
                        "dummy-auth-code"
                    },
                    getTokenResponse: { tokenRequest in try await self.exchangeToken(tokenRequest, proxy: false) },
                    getProofJwt: { credentialIssuer, cNonce, _ in
                        self.signProofJWT(
                            cNonce: cNonce,
                            issuer: credentialIssuer,
                            isTrustedIssuer: false
                        )
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

                let credentialResponse = try await client.requestCredentialFromTrustedIssuer(
                    credentialIssuer: credentialIssuer ,
                    credentialConfigurationId: credentialConfigurationId,
                    clientMetadata: ClientMetadata(clientId: clientId, redirectUri: redirectUri),
                    authorizeUser: { authEndpoint in
                        await withCheckedContinuation { continuation in
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
                    },
                    getTokenResponse: { tokenRequest in try await self.exchangeToken(tokenRequest, proxy: true) },
                    getProofJwt: { credentialIssuer, cNonce, _ in
                        self.signProofJWT(
                            cNonce: cNonce,
                            issuer: credentialIssuer,
                            isTrustedIssuer: true
                        )
                    })

                if let vc = try credentialResponse?.toJsonString() {
                    onResult("✅ Credential Issued:\n\(vc)")
                } else {
                    onResult("Downloading VC")
                }
            } catch {
            }
        }
    }
    
    func fetchCredentialTypes(
        from credentialIssuer: String,
        onResult: @escaping (_ rawJson: String, _ keys: [String]) -> Void
    ) {
        Task {
            do {
                let client = VCIClient(traceabilityId: "demo-trace-id")
                let types = try await client.getCredentialConfigurationsSupported(credentialIssuer: credentialIssuer)

                let rawJson = try types.toJsonString()
                let keys = Array(types.keys)

                onResult(rawJson, keys)
            } catch {
                onResult("❌ Error: \(error.localizedDescription)", [])
            }
        }
    }


    private func signProofJWT(cNonce: String?, issuer: String, isTrustedIssuer: Bool?) -> String {
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

        var nonceToUse = cNonce
        let now = Int(Date().timeIntervalSince1970)

        let payload: [String: Any] = [
            "aud": issuer,
            "nonce": nonceToUse,
            "iat": now,
            "exp": now + 18000,
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

    private func exchangeToken(_ req: TokenRequest, proxy: Bool) async throws -> TokenResponse {
        // Build form-url-encoded body
        var items: [URLQueryItem] = [
            URLQueryItem(name: "grant_type", value: req.grantType.rawValue),
        ]
        if let code = req.authCode { items.append(URLQueryItem(name: "code", value: code)) }
        if let codeVerifier = req.codeVerifier { items.append(URLQueryItem(name: "code_verifier", value: codeVerifier)) }
        if let pac = req.preAuthCode { items.append(URLQueryItem(name: "pre-authorized_code", value: pac)) }
        if let tx = req.txCode { items.append(URLQueryItem(name: "tx_code", value: tx)) }
        if let clientId = req.clientId { items.append(URLQueryItem(name: "client_id", value: clientId)) }
        if let redirectUri = req.redirectUri { items.append(URLQueryItem(name: "redirect_uri", value: redirectUri)) }
        let encodedBody = formURLEncode(items: items)
        guard let url = URL(string: proxy ? proxyTokenEndpoint : req.tokenEndpoint) else {
            throw NSError(domain: "VCIClientWrapper", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid token endpoint"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formURLEncode(items: items).data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            let txt = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "VCIClientWrapper",
                          code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "Token error: \(txt)"])
        }
        let decoder = JSONDecoder()
        return try decoder.decode(TokenResponse.self, from: data)
    }

    private func formURLEncode(items: [URLQueryItem]) -> String {
        items.map { qi in
            let k = qi.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? qi.name
            let v = (qi.value ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "\(k)=\(v)"
        }.joined(separator: "&")
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

extension Dictionary where Key == String, Value == Any {
    func toJsonString(pretty: Bool = true) throws -> String {
        let options: JSONSerialization.WritingOptions = pretty ? .prettyPrinted : []
        let data = try JSONSerialization.data(withJSONObject: self, options: options)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
