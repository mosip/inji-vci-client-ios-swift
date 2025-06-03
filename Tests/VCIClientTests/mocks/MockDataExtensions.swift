import Foundation
@testable import VCIClient

extension IssuerMetadata {
    static func mock() -> IssuerMetadata {
        return IssuerMetadata(
            credentialAudience: "https://example.com",
            credentialEndpoint: "https://example.com/credential",
            credentialFormat: .mso_mdoc,
            doctype: "org.iso.18013.5.1.mDL",
            claims: ["name": AnyCodable("John Doe")],
            authorizationServers: ["https://auth.example.com"]
        )
    }
}

extension CredentialOffer {
    static func mock() -> CredentialOffer {
        return CredentialOffer(
            credentialIssuer: "https://mock-issuer",
            credentialConfigurationIds: ["mock-id"],
            grants: CredentialOfferGrants(
                preAuthorizedGrant: PreAuthorizedCodeGrant(
                    preAuthorizedCode: "pre-auth-code",
                    txCode: nil,
                    authorizationServer: nil,
                    interval: nil
                ),
                authorizationCodeGrant: nil
            )
        )
    }

    static func mockWithTxCodeRequired() -> CredentialOffer {
        return CredentialOffer(
            credentialIssuer: "https://mock-issuer",
            credentialConfigurationIds: ["mock-id"],
            grants: CredentialOfferGrants(
                preAuthorizedGrant: PreAuthorizedCodeGrant(
                    preAuthorizedCode: "pre-auth-code",
                    txCode: TxCode(inputMode: "text", length: 5, description: "provide pin"),
                    authorizationServer: nil,
                    interval: nil
                ),
                authorizationCodeGrant: nil
            )
        )
    }

    static func mockWithoutGrant() -> CredentialOffer {
        return CredentialOffer(
            credentialIssuer: "mock-issuer", credentialConfigurationIds: ["mock-id"], grants: nil
        )
    }
}

extension CredentialResponse {
    static func mock() -> CredentialResponse {
        let fakeCredential = [
            "id": "urn:uuid:1234-abcd",
            "type": ["VerifiableCredential"],
            "issuer": "https://example.com/issuer",
            "credentialSubject": [
                "name": "Test User",
                "dob": "2000-01-01",
            ],
        ] as [String: Any]

        return CredentialResponse(credential: AnyCodable(fakeCredential))
    }
}


extension TokenResponse {
    static func mock() -> TokenResponse {
        return TokenResponse(
            accessToken: "mock-access-token",
            tokenType: "Bearer",
            expiresIn: 3600
        )
    }
}
