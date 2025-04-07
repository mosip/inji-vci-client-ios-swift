
import XCTest
@testable import VCIClient

final class CredentialOfferValidatorTests: XCTestCase {

    func testValidate_Success() throws {
        let offer = CredentialOffer(
            credentialIssuer: "https://issuer.example.com",
            credentialConfigurationIds: ["UniversityDegreeCredential"],
            grants: CredentialOfferGrants(
                preAuthorizedGrant: PreAuthorizedCodeGrant(preAuthorizedCode: "1234", txCode: TxCode(inputMode: "email", length: 9, description: ""), authorizationServer: nil, interval: nil ),
                authorizationCodeGrant: nil
            )
        )

        XCTAssertNoThrow(try CredentialOfferValidator.validate(offer))
    }

    func testValidate_ThrowsOnEmptyCredentialIssuer() {
        let offer = CredentialOffer(
            credentialIssuer: "   ",
            credentialConfigurationIds: ["Valid"],
            grants: nil
        )

        XCTAssertThrowsError(try CredentialOfferValidator.validate(offer)) { error in
            XCTAssertEqual(error as? OfferValidationError, .emptyCredentialIssuer)
        }
    }

    func testValidate_ThrowsOnInvalidIssuerScheme() {
        let offer = CredentialOffer(
            credentialIssuer: "http://issuer.com",
            credentialConfigurationIds: ["Valid"],
            grants: nil
        )

        XCTAssertThrowsError(try CredentialOfferValidator.validate(offer)) { error in
            XCTAssertEqual(error as? OfferValidationError, .invalidCredentialIssuerScheme)
        }
    }

    func testValidate_ThrowsOnEmptyCredentialConfigurationIds() {
        let offer = CredentialOffer(
            credentialIssuer: "https://issuer.example.com",
            credentialConfigurationIds: [],
            grants: nil
        )

        XCTAssertThrowsError(try CredentialOfferValidator.validate(offer)) { error in
            XCTAssertEqual(error as? OfferValidationError, .emptyCredentialConfigurationIds)
        }
    }

    func testValidate_ThrowsOnBlankCredentialConfigurationId() {
        let offer = CredentialOffer(
            credentialIssuer: "https://issuer.example.com",
            credentialConfigurationIds: ["   "],
            grants: nil
        )

        XCTAssertThrowsError(try CredentialOfferValidator.validate(offer)) { error in
            XCTAssertEqual(error as? OfferValidationError, .blankCredentialConfigurationId)
        }
    }

    func testValidate_ThrowsOnMissingGrantType() {
        let offer = CredentialOffer(
            credentialIssuer: "https://issuer.example.com",
            credentialConfigurationIds: ["Valid"],
            grants: CredentialOfferGrants(preAuthorizedGrant: nil, authorizationCodeGrant: nil)
        )

        XCTAssertThrowsError(try CredentialOfferValidator.validate(offer)) { error in
            XCTAssertEqual(error as? OfferValidationError, .missingGrantType)
        }
    }

    func testValidate_ThrowsOnBlankPreAuthorizedCode() {
        let offer = CredentialOffer(
            credentialIssuer: "https://issuer.example.com",
            credentialConfigurationIds: ["Valid"],
            grants: CredentialOfferGrants(
                preAuthorizedGrant: PreAuthorizedCodeGrant(preAuthorizedCode: "", txCode: TxCode(inputMode: "email", length: 9, description: ""), authorizationServer: nil, interval: nil ),
                authorizationCodeGrant: nil
            )
        )

        XCTAssertThrowsError(try CredentialOfferValidator.validate(offer)) { error in
            XCTAssertEqual(error as? OfferValidationError, .blankPreAuthorizedCode)
        }
    }

    func testValidate_ThrowsOnInvalidTxCodeLength() {
        let offer = CredentialOffer(
            credentialIssuer: "https://issuer.example.com",
            credentialConfigurationIds: ["Valid"],
            grants: CredentialOfferGrants(
                preAuthorizedGrant: PreAuthorizedCodeGrant(preAuthorizedCode: "1234", txCode: TxCode(inputMode: "email", length: 0, description: ""), authorizationServer: nil, interval: nil ),
                authorizationCodeGrant: nil
            )
        )

        XCTAssertThrowsError(try CredentialOfferValidator.validate(offer)) { error in
            XCTAssertEqual(error as? OfferValidationError, .invalidTxCodeLength)
        }
    }
}
