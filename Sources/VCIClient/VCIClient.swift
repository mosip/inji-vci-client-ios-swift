import Foundation

public class VCIClient {
    let networkSession: NetworkManager
    let traceabilityId: String
    let credentialOfferFlowHandler: CredentialOfferFlowHandler
    let trustedIssuerFlowHandler: TrustedIssuerFlowHandler
    let issuerMetadataService: IssuerMetadataService
    let credentialRequestFactory: CredentialRequestFactoryProtocol


    public init(traceabilityId: String
    ) {
        self.traceabilityId = traceabilityId
        credentialOfferFlowHandler = CredentialOfferFlowHandler()
        trustedIssuerFlowHandler = TrustedIssuerFlowHandler()
        issuerMetadataService = IssuerMetadataService()
        networkSession = NetworkManager.shared
        credentialRequestFactory = CredentialRequestFactory()
    }

    init(traceabilityId: String?,
         networkSession: NetworkManager? = nil,
         credentialRequestFactory: CredentialRequestFactoryProtocol? = nil,
         credentialOfferHandler: CredentialOfferFlowHandler? = nil,
         trustedIssuerFlowHandler: TrustedIssuerFlowHandler? = nil,
         issuerMetadataService: IssuerMetadataService? = nil
    ) {
        self.traceabilityId = traceabilityId ?? ""
        self.networkSession = networkSession ?? NetworkManager.shared
        self.credentialOfferFlowHandler = credentialOfferHandler ?? CredentialOfferFlowHandler()
        self.trustedIssuerFlowHandler = trustedIssuerFlowHandler ?? TrustedIssuerFlowHandler()
        self.issuerMetadataService = issuerMetadataService ?? IssuerMetadataService()
        self.credentialRequestFactory = credentialRequestFactory ?? CredentialRequestFactory()
    }

    private var logTag: String {
        Util.getLogTag(className: String(describing: type(of: self)), traceabilityId: traceabilityId)
    }

    public func requestCredentialByCredentialOffer(
        credentialOffer: String,
        clientMetadata: ClientMetadata,
        getTxCode: TxCodeCallback,
        authorizeUser: @escaping AuthorizeUserCallback,
        getTokenResponse: @escaping TokenResponseCallback,
        getProofJwt: @escaping ProofJwtCallback,
        onCheckIssuerTrust: CheckIssuerTrustCallback = nil,
        downloadTimeoutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis
    ) async throws -> CredentialResponse? {
        do {
            return try await credentialOfferFlowHandler.downloadCredentials(
                credentialOffer: credentialOffer,
                clientMetadata: clientMetadata,
                getTxCode: getTxCode,
                authorizeUser: authorizeUser,
                getTokenResponse: getTokenResponse,
                getProofJwt: getProofJwt,
                onCheckIssuerTrust: onCheckIssuerTrust,
                networkSession: networkSession,
                downloadTimeoutInMillis: downloadTimeoutInMillis
            )
        } catch let e as VCIClientException {
            throw e
        } catch {
            throw VCIClientException(code: "VCI-010", message: "Unknown exception occurred")
        }
    }

    public func getIssuerMetadata(credentialIssuer: String) async throws -> [String: Any] {
        return try await issuerMetadataService.fetchAndParseIssuerMetadata(from: credentialIssuer)
    }
    
    public func getCredentialConfigurationsSupported(credentialIssuer: String) async throws -> [String:Any]{
        return try await issuerMetadataService.fetchCredentialConfigurationsSupported(from: credentialIssuer)
    }

    public func requestCredentialFromTrustedIssuer(
        credentialIssuer: String,
        credentialConfigurationId: String,
        clientMetadata: ClientMetadata,
        authorizeUser: @escaping AuthorizeUserCallback,
        getTokenResponse: @escaping TokenResponseCallback,
        getProofJwt: @escaping ProofJwtCallback,
        downloadTimeoutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis
    ) async throws -> CredentialResponse? {
        do {

            return try await trustedIssuerFlowHandler.downloadCredentials(
                credentialIssuer: credentialIssuer,
                credentialConfigurationId: credentialConfigurationId,
                clientMetadata: clientMetadata,
                authorizeUser: authorizeUser,
                getTokenResponse: getTokenResponse,
                getProofJwt: getProofJwt,
                downloadTimeoutInMillis: downloadTimeoutInMillis,
                networkSession: networkSession
            )
        } catch let e as VCIClientException {
            throw e
        } catch {
            throw VCIClientException(
                code: "VCI-010",
                message: "Unknown exception occurred"
            )
        }
    }

    @available(*, deprecated, message: "This method is deprecated as per the new VCI Client library contract.Use requestCredentialByCredentialOffer() or requestCredentialFromTrustedIssuer()")
    public func requestCredential(
        issuerMeta: IssuerMeta,
        proof: Proof,
        accessToken: String
    ) async throws -> CredentialResponse? {
        do {
            let issuerMetadata = IssuerMetadata(
                credentialIssuer: issuerMeta.credentialAudience,
                credentialEndpoint: issuerMeta.credentialEndpoint,
                credentialType: issuerMeta.credentialType,
                context: nil,
                credentialFormat: issuerMeta.credentialFormat,
                doctype: issuerMeta.docType,
                claims: issuerMeta.claims?.mapValues { AnyCodable($0) },
                authorizationServers: nil,
                tokenEndpoint: nil,
                scope: "openId"
            )
            var request = try credentialRequestFactory.createCredentialRequest(
                credentialFormat: issuerMetadata.credentialFormat,
                accessToken: accessToken,
                issuer: issuerMetadata,
                proofJwt: proof
            )

            request.timeoutInterval = TimeInterval(issuerMeta.downloadTimeoutInMilliseconds) / 1000

            let networkResponse = try await networkSession.sendRequest(request: request)
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
            print("\(logTag) Request timed out after \(issuerMeta.downloadTimeoutInMilliseconds / 1000)s")
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
