import Foundation

class CredentialRequestExecutor {
    private let logTag = "[CredentialRequestExecutor]"

    func requestCredential(
        issuerMetadata: IssuerMetadata,
        proof: Proof,
        accessToken: String,
        timeoutInMillis: Int64 = 10000,
        session: NetworkManager = NetworkManager.shared
    ) async throws -> CredentialResponse? {
        do {
            var request = try CredentialRequestFactory().createCredentialRequest(
                credentialFormat: issuerMetadata.credentialFormat,
                accessToken: accessToken,
                issuer: issuerMetadata,
                proofJwt: proof
            )

            request.timeoutInterval = TimeInterval(timeoutInMillis) / 1000

            let networkResponse = try await session.sendRequest(request: request)
            let responseBody = networkResponse.body

            print("\(logTag) Credential downloaded successfully.")

            if !responseBody.isEmpty {
                guard let result = try JsonUtils.deserialize(responseBody, as: CredentialResponse.self) else {
                    throw DownloadFailedException("Failed to parse credential response.")
                }
                return result
            }

            print("\(logTag) Response body is empty.")
            return nil

        } catch let error as NetworkRequestTimeoutException {
            print("\(logTag) Request timed out after \(timeoutInMillis / 1000)s")
            throw error
        } catch let error as DownloadFailedException {
            throw error
        } catch let error as InvalidAccessTokenException {
            throw error
        } catch let error as InvalidPublicKeyException {
            throw error
        } catch {
            print("\(logTag) Unexpected error: \(error.localizedDescription)")
            throw DownloadFailedException(error.localizedDescription)
        }
    }
}
