import Foundation

extension CredentialOffer {
    var isPreAuthorizedFlow: Bool {
        return grants?.preAuthorizedGrant != nil
    }

    var isAuthorizationCodeFlow: Bool {
        return grants?.authorizationCodeGrant != nil || grants == nil
    }
}
