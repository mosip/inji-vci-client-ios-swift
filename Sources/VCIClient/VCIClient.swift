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
                trustedIssuerRegistry:trustedIssuerRegistry
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
}
