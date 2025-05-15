import Foundation

public class CredentialOfferHandler {
    public init() {}

    func downloadCredentials(
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
        networkSession: NetworkManager = NetworkManager.shared,
        downloadTimeoutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis,
        trustedIssuerRegistry: TrustedIssuerRegistry
    ) async throws -> CredentialResponse {
        let offer = try await CredentialOfferService().fetchCredentialOffer(credentialOffer)

        let issuerMetadataResponse = try await IssuerMetadataService().fetch(
            issuerUrl: offer.credentialIssuer,
            credentialConfigurationId: offer.credentialConfigurationIds.first ?? ""
        )

        let issuerMeta = issuerMetadataResponse.issuerMetadata
        let rawMeta = issuerMetadataResponse.raw
        let issuer = issuerMeta.credentialAudience

        try await ensureIssuerTrust(rawMeta as [String: Any], issuer: issuer, onCheck: onCheckIssuerTrust, trustRegistry: trustedIssuerRegistry)

        if offer.isPreAuthorizedFlow {
            return try await PreAuthFlowService().requestCredentials(
                issuerMetadataResult: issuerMetadataResponse,
                offer: offer,
                getTxCode: getTxCode,
                getProofJwt: getProofJwt,
                credentialConfigurationId: offer.credentialConfigurationIds.first!,
                downloadTimeoutInMillis: downloadTimeoutInMillis
            )
        } else if offer.isAuthorizationCodeFlow {
            return try await AuthorizationCodeFlowService().requestCredentials(
                issuerMetadataResult: issuerMetadataResponse,
                clientMetadata: clientMetadata,
                credentialOffer: offer,
                getAuthCode: getAuthCode,
                getProofJwt: getProofJwt,
                credentialConfigurationId: offer.credentialConfigurationIds.first,
                downloadTimeOutInMillis: downloadTimeoutInMillis
            )
        } else {
            throw OfferFetchFailedException("Credential offer does not contain a supported grant type")
        }
    }

    private func ensureIssuerTrust(
        _ rawMetadata: [String: Any],
        issuer: String,
        onCheck: ((_ issuerMetadata: [String: Any]) async throws -> Bool)?,
        trustRegistry: TrustedIssuerRegistry
    ) async throws {
        guard !trustRegistry.isTrusted(issuer: issuer), let onCheck = onCheck else { return }

        let consented = try await onCheck(rawMetadata)
        if consented {
            trustRegistry.markTrusted(issuer: issuer)
        } else {
            throw OfferFetchFailedException("Issuer not trusted by user")
        }
    }
}
