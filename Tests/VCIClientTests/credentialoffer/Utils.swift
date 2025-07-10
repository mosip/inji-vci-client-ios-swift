
@testable import VCIClient
import XCTest

final class CredentialOfferExtensionTests: XCTestCase {
    func testIsPreAuthorizedFlow_trueWhenPreAuthorizedGrantExists() {
        let offer = CredentialOffer(credentialIssuer: "test",
                                    credentialConfigurationIds: ["test_id"],
                                    grants: CredentialOfferGrants(
                                        preAuthorizedGrant: PreAuthCodeGrant(preAuthCode: "test-123", txCode: nil, authorizationServer: nil, interval: nil),
                                        authorizationCodeGrant: nil
                                    ))

        XCTAssertTrue(offer.isPreAuthorizedFlow)
    }

    func testIsPreAuthorizedFlow_falseWhenPreAuthorizedGrantNil() {
        let offer = CredentialOffer(
            credentialIssuer: "test",
            credentialConfigurationIds: ["test_id"],
            grants: CredentialOfferGrants(
                preAuthorizedGrant: nil,
                authorizationCodeGrant: AuthorizationCodeGrant(issuerState: nil, authorizationServer: nil)
            ))

        XCTAssertFalse(offer.isPreAuthorizedFlow)
    }

    func testIsPreAuthorizedFlow_falseWhenGrantsNil() {
        let offer = CredentialOffer(credentialIssuer: "test",
                                    credentialConfigurationIds: ["test_id"], grants: nil)
        XCTAssertFalse(offer.isPreAuthorizedFlow)
    }

    func testIsAuthorizationCodeFlow_trueWhenAuthorizationCodeGrantExists() {
        let offer = CredentialOffer(
            credentialIssuer: "test",
            credentialConfigurationIds: ["test_id"],
            grants: CredentialOfferGrants(
                preAuthorizedGrant: nil,
                authorizationCodeGrant: AuthorizationCodeGrant(issuerState: nil, authorizationServer: nil)
            ))

        XCTAssertTrue(offer.isAuthorizationCodeFlow)
    }
}
