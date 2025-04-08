import Foundation

public class VCIClient {
    
    let networkSession: NetworkSession
    let traceabilityId: String
    let credentialRequestFactory: CredentialRequestFactoryProtocol
    
    public init(traceabilityId: String,
                networkSession: NetworkSession? = nil,
                credentialRequestFactory: CredentialRequestFactoryProtocol? = nil ) {
        self.traceabilityId = traceabilityId
        self.networkSession = networkSession ?? URLSession.shared
        self.credentialRequestFactory = credentialRequestFactory ?? CredentialRequestFactory.shared
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
            
            let request = try credentialRequestFactory.createCredentialRequest(
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
                return try JSONDecoder().decode(CredentialResponse.self, from: data)
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
    
    public func fetchCredentialOffer(_ credentialOfferData: String) async throws -> CredentialOffer {
        do {
            
            let normalized = credentialOfferData.replacingOccurrences(of: "openid-credential-offer://?", with: "openid-credential-offer://dummy?")
            
            guard let url = URL(string: normalized),
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems, queryItems.count > 0 else {
                throw CredentialOfferError.invalidOffer( description: "Invalid or missing query parameters")
            }
            
            
            let queryParams = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })
            
            
            let credentialOfferService = CredentialOfferService()
            
            if let offer = queryParams["credential_offer"] {
                return try credentialOfferService.handleByValueOffer(encodedOffer: offer)
            } else if let uri = queryParams["credential_offer_uri"] {
                return try await credentialOfferService.handleByReferenceOffer(from: uri)
            } else {
                throw CredentialOfferError.invalidOffer(description:"Missing credential_offer or credential_offer_uri")
            }
        } catch {
            throw CredentialOfferError.invalidOffer(description: "Failed to parse credential offer: \(error.localizedDescription)")
        }
    }
    
    public func requestCredentialByPreAuthFlow(
        issuerMetaData: IssuerMeta,
        txCode: String?,
        getProofJwt: @escaping (_ accessToken: String, _ cNonce: String?) async throws -> String,
        networkSession: NetworkSession = URLSession.shared
    ) async throws -> CredentialResponse? {
        
        let tokenService = PreAuthTokenService()
        let tokenResponse = try await tokenService.exchangePreAuthCodeForToken(
            issuerMetaData: issuerMetaData,
            txCode: txCode,
            session: networkSession
        )
        
        let jwt = try await getProofJwt(tokenResponse.accessToken, tokenResponse.cNonce)
        let proof =  JWTProof(jwt: jwt)
        
        let response = try await requestCredential(issuerMeta: issuerMetaData, proof: proof, accessToken: tokenResponse.accessToken)
        return response
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
