import Foundation

public class VCIClient {
    
    let networkSession: NetworkSession
    let traceabilityId: String
    
    public init(traceabilityId: String, networkSession: NetworkSession? = nil) {
        self.traceabilityId = traceabilityId
        self.networkSession = networkSession ?? URLSession.shared
    }
    
    public func requestCredential(
        issuerMeta: IssuerMeta,
        proof: Proof,
        accessToken: String
    ) async throws -> CredentialResponse? {
        let logTag = Util.getLogTag(className: String(describing: type(of: self)), traceabilityId: traceabilityId)
        do {
            
            guard let url = URL(string: issuerMeta.credentialEndpoint) else {
                throw DownloadFailedError.invalidURL
            }
            
            let request = CredentialRequestfactory.createCredentialRequest(
                url: url,
                credentialFormat: issuerMeta.credentialFormat,
                accessToken: accessToken,
                issuer: issuerMeta,
                proofJwt: proof
            )
            
            let (data, response) = try await networkSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw DownloadFailedError.noResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                let statusCode = httpResponse.statusCode
                let errorDescription = HTTPURLResponse.localizedString(forStatusCode: statusCode)
                print(logTag,
                      "Downloading credential failed with response code \(statusCode) - \(errorDescription)"
                )
                throw DownloadFailedError.httpError(statusCode: statusCode, description: errorDescription)
            }
            
            if !data.isEmpty {
                let credentialResponse = try CredentialResponseFactory.createCredentialResponse(
                    formatType: issuerMeta.credentialFormat,
                    response: data
                )
                print(logTag, "credential downloaded successfully!")
                return credentialResponse
            } else {
                print(
                    logTag,
                    "The response body from credentialEndpoint is empty, responseCode - \(httpResponse.statusCode), responseMessage \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)), returning null."
                )
                throw DownloadFailedError.noResponse
            }
        } catch {
            try handleError(error: error, logTag: logTag)
            return nil
        }
    }
    
    private func handleError(error: Error, logTag: String) throws {
        switch error {
        case let nsError as NSError where nsError.domain == NSURLErrorDomain:
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                throw DownloadFailedError.httpError(statusCode: NSURLErrorNotConnectedToInternet, description: "No internet connection")
            case NSURLErrorTimedOut:
                throw NetworkRequestTimeOutError.networkRequestTimeOutError
            default:
                throw DownloadFailedError.httpError(statusCode: nsError.code, description: nsError.localizedDescription)
            }
        case is DownloadFailedError:
            let description = "Download failed due to \(error)"
            print("\(logTag) \(description)")
            throw DownloadFailedError.customError(description: description)
        default:
            print("\(logTag) Unknown error :", error)
            throw error
        }
    }
}
