import Foundation

struct CredentialOfferValidator {
    static func validate(_ offer: CredentialOffer) throws {
        try validateCredentialIssuer(offer.credentialIssuer)
        try validateCredentialConfigurationIds(offer.credentialConfigurationIds)
        try validateGrants(offer.grants)
    }

    private static func validateCredentialIssuer(_ issuer: String) throws {
        if issuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw OfferValidationError.emptyCredentialIssuer
        }
        if !issuer.starts(with: "https://") {
            throw OfferValidationError.invalidCredentialIssuerScheme
        }
    }

    private static func validateCredentialConfigurationIds(_ configIds: [String]) throws {
        if configIds.isEmpty {
            throw OfferValidationError.emptyCredentialConfigurationIds
        }
        if configIds.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            throw OfferValidationError.blankCredentialConfigurationId
        }
    }

    private static func validateGrants(_ grants: CredentialOfferGrants?) throws {
        guard let grants = grants else { return }

        if grants.preAuthorizedGrant == nil && grants.authorizationCodeGrant == nil {
            throw OfferValidationError.missingGrantType
        }

        if let preAuth = grants.preAuthorizedGrant {
            if preAuth.preAuthorizedCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw OfferValidationError.blankPreAuthorizedCode
            }

            if let txCode = preAuth.txCode, let length = txCode.length, length <= 0 {
                throw OfferValidationError.invalidTxCodeLength
            }
        }
    }
}
