import Foundation

public class VCIClient {
    let networkSession: NetworkManager
    let traceabilityId: String
    let credentialOfferHandler: CredentialOfferHandler
    let trustedIssuerHandler: TrustedIssuerHandler
    private let trustedIssuerRegistry = TrustedIssuerRegistry()

    public init(traceabilityId: String,
                networkSession: NetworkManager? = nil,
                credentialRequestFactory: CredentialRequestFactoryProtocol? = nil,
                credentialOfferHandler: CredentialOfferHandler? = nil,
                trustedIssuerHandler: TrustedIssuerHandler? = nil
    ) {
        self.traceabilityId = traceabilityId
        self.networkSession = networkSession ?? NetworkManager.shared
        self.credentialOfferHandler = credentialOfferHandler ?? CredentialOfferHandler()
        self.trustedIssuerHandler = trustedIssuerHandler ?? TrustedIssuerHandler()
    }

    private var logTag: String {
        Util.getLogTag(className: String(describing: type(of: self)), traceabilityId: traceabilityId)
    }

    public func requestCredentialByCredentialOffer(
        credentialOffer: String,
        clientMetadata: ClientMetaData,
        getTxCode: ((_ inputMode: String?, _ description: String?, _ length: Int?) async throws -> String)?,
        getProofJwt: @escaping (
            _ accessToken: String,
            _ cNonce: String?,
            _ issuerMetadata: [String: Any]?,
            _ credentialConfigurationId: String?
        ) async throws -> String,
        getAuthCode: @escaping (_ authorizationEndpoint: String) async throws -> String,
        onCheckIssuerTrust: ((_ issuerMetadata: [String: Any]) async throws -> Bool)? = nil,
        downloadTimeoutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis
    ) async throws -> CredentialResponse? {
        do {
            return try await credentialOfferHandler.downloadCredentials(
                credentialOffer: credentialOffer,
                clientMetadata: clientMetadata,
                getTxCode: getTxCode,
                getProofJwt: getProofJwt,
                getAuthCode: getAuthCode,
                onCheckIssuerTrust: onCheckIssuerTrust,
                networkSession: networkSession,
                downloadTimeoutInMillis: downloadTimeoutInMillis,
                trustedIssuerRegistry: trustedIssuerRegistry
            )
        } catch let e as VCIClientException {
            throw e
        } catch {
            throw VCIClientException(code: "VCI-010", message: "Unknown exception occurred")
        }
    }

    public func requestCredentialFromTrustedIssuer(
        issuerMetadata: IssuerMetadata,
        clientMetadata: ClientMetaData,
        getProofJwt: @escaping (
            _ accessToken: String,
            _ cNonce: String?,
            _ issuerMetadata: [String: Any]?,
            _ credentialConfigurationId: String?
        ) async throws -> String,
        getAuthCode: @escaping (_ authorizationEndpoint: String) async throws -> String,
        downloadTimeoutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis
    ) async throws -> CredentialResponse? {
        do {
            return try await trustedIssuerHandler.downloadCredentials(
                issuerMetadata: issuerMetadata,
                clientMetadata: clientMetadata,
                getAuthCode: getAuthCode,
                getProofJwt: getProofJwt,
                downloadTimeoutInMillis: downloadTimeoutInMillis,
                networkSession: networkSession
            )
        } catch let e as VCIClientException {
            throw e
        } catch {
            throw VCIClientException(code: "VCI-010", message: "Unknown exception occurred")
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
                credentialAudience: issuerMeta.credentialAudience,
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
            var request = try CredentialRequestFactory().createCredentialRequest(
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
