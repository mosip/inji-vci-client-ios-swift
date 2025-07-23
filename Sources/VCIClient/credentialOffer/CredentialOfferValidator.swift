import Foundation

struct CredentialOfferValidator {
    static func validate(_ offer: CredentialOffer) throws {
        try validateCredentialIssuer(offer.credentialIssuer)
        try validateCredentialConfigurationIds(offer.credentialConfigurationIds)
        try validateGrants(offer.grants)
    }

    private static func validateCredentialIssuer(_ issuer: String) throws {
        if issuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw CredentialOfferFetchFailedException("credential_issuer must not be blank")
        }
        if !issuer.starts(with: "https://") {
            throw CredentialOfferFetchFailedException("credential_issuer must use HTTPS scheme")
        }
    }

    private static func validateCredentialConfigurationIds(_ configIds: [String]) throws {
        if configIds.isEmpty {
            throw CredentialOfferFetchFailedException("credential_configuration_ids must not be empty")
        }
        if configIds.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            throw CredentialOfferFetchFailedException("credential_configuration_ids must not contain blank values")
        }
    }

    private static func validateGrants(_ grants: CredentialOfferGrants?) throws {
        guard let grants = grants else { return }

        if grants.preAuthorizedGrant == nil && grants.authorizationCodeGrant == nil {
            throw CredentialOfferFetchFailedException("grants must contain at least one supported grant type")
        }

        if let preAuth = grants.preAuthorizedGrant {
            if preAuth.preAuthCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw CredentialOfferFetchFailedException("pre-authorized_code must not be blank")
            }

            if let txCode = preAuth.txCode, let length = txCode.length, length <= 0 {
                throw CredentialOfferFetchFailedException("tx_code.length must be greater than 0")
            }
        }
    }
}
