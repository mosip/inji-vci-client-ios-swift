import Foundation

enum OfferValidationError: Error, LocalizedError {
    case emptyCredentialIssuer
    case invalidCredentialIssuerScheme
    case emptyCredentialConfigurationIds
    case blankCredentialConfigurationId
    case missingGrantType
    case blankPreAuthorizedCode
    case invalidTxCodeLength

    var errorDescription: String? {
        switch self {
        case .emptyCredentialIssuer:
            return "credential_issuer must not be blank"
        case .invalidCredentialIssuerScheme:
            return "credential_issuer must use HTTPS scheme"
        case .emptyCredentialConfigurationIds:
            return "credential_configuration_ids must not be empty"
        case .blankCredentialConfigurationId:
            return "credential_configuration_ids must not contain blank values"
        case .missingGrantType:
            return "grants must contain at least one supported grant type"
        case .blankPreAuthorizedCode:
            return "pre-authorized_code must not be blank"
        case .invalidTxCodeLength:
            return "tx_code.length must be greater than 0"
        }
    }
}
