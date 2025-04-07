import Foundation

public struct CredentialOffer: Codable {
    let credentialIssuer: String
    let credentialConfigurationIds: [String]
    let grants: CredentialOfferGrants?

    enum CodingKeys: String, CodingKey {
        case credentialIssuer = "credential_issuer"
        case credentialConfigurationIds = "credential_configuration_ids"
        case grants
    }
}

 struct CredentialOfferGrants: Codable {
    let preAuthorizedGrant: PreAuthorizedCodeGrant?
    let authorizationCodeGrant: AuthorizationCodeGrant?

    enum CodingKeys: String, CodingKey {
        case preAuthorizedGrant = "urn:ietf:params:oauth:grant-type:pre-authorized_code"
        case authorizationCodeGrant = "authorization_code"
    }
}

 struct PreAuthorizedCodeGrant: Codable {
    let preAuthorizedCode: String
    let txCode: TxCode?
    let authorizationServer: String?
    let interval: Int?

    enum CodingKeys: String, CodingKey {
        case preAuthorizedCode = "pre-authorized_code"
        case txCode = "tx_code"
        case authorizationServer = "authorization_server"
        case interval
    }
}

 struct TxCode: Codable {
    let inputMode: String?
    let length: Int?
    let description: String?
}

  struct AuthorizationCodeGrant: Codable {
    let issuerState: String?
    let authorizationServer: String?

    enum CodingKeys: String, CodingKey {
        case issuerState = "issuer_state"
        case authorizationServer = "authorization_server"
    }
}
