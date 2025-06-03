import CryptoKit
import Foundation

class PKCESessionManager {
    struct PKCESession {
        let codeVerifier: String
        let codeChallenge: String
        let state: String
        let nonce: String
    }

    private let codeVerifierByteSize = 64

    func createSession() -> PKCESession {
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(codeVerifier)
        let state = generateRandomString()
        let nonce = generateRandomString()
        return PKCESession(
            codeVerifier: codeVerifier,
            codeChallenge: codeChallenge,
            state: state,
            nonce: nonce
        )
    }

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: codeVerifierByteSize)
        _ = SecRandomCopyBytes(kSecRandomDefault, codeVerifierByteSize, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    private func generateCodeChallenge(_ verifier: String) -> String {
        let inputData = Data(verifier.utf8)
        let hashed = SHA256.hash(data: inputData)
        return Data(hashed).base64URLEncodedString()
    }

    private func generateRandomString() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}
