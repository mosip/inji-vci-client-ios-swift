import XCTest
@testable import VCIClient
final class CredentialOfferHandlerTests: XCTestCase {

    private func makeMinimalIssuerMetadataResult() -> IssuerMetadataResult {
        return IssuerMetadataResult(
            issuerMetadata: IssuerMetadata(
                credentialAudience: "aud",
                credentialEndpoint: "https://example.com",
                credentialFormat: .ldp_vc
            ),
            raw: [:]
        )
    }

    private func makeMinimalCredentialResponse() -> CredentialResponse {
        return CredentialResponse(credential: .init("mock-credential"))
    }

    func testPreAuthorizedFlow_callsPreAuthFlowService() async throws {
        let offerService = MockCredentialOfferService()
        offerService.offerToReturn = CredentialOffer(
            credentialIssuer: "https://issuer.com",
            credentialConfigurationIds: ["config"],
            grants: CredentialOfferGrants(preAuthorizedGrant: PreAuthorizedCodeGrant(preAuthorizedCode: "test", txCode: nil, authorizationServer: nil, interval: nil), authorizationCodeGrant: nil)
        )

        let issuerService = MockIssuerMetadataService()
        issuerService.resultToReturn = makeMinimalIssuerMetadataResult()

        let preAuthFlowService = MockPreAuthFlowService()
        preAuthFlowService.responseToReturn = makeMinimalCredentialResponse()

        let handler = CredentialOfferHandler(
            credentialOfferService: offerService,
            issuerMetadataService: issuerService,
            preAuthFlowService: preAuthFlowService,
            authorizationCodeFlowService: MockAuthorizationCodeFlowService()
        )

        let result = try await handler.downloadCredentials(
            credentialOffer: "offer",
            clientMetadata: ClientMetaData(clientId: "id", redirectUri: "uri"),
            getTxCode: { _,_,_ in "tx-code" },
            getProofJwt: { _, _, _, _ in "jwt" },
            getAuthCode: { _ in "auth-code" }
        )

        
        XCTAssertTrue(preAuthFlowService.didCallRequest)
    }

    func testAuthorizationCodeFlow_callsAuthCodeFlowService() async throws {
        let offerService = MockCredentialOfferService()
        offerService.offerToReturn = CredentialOffer(
            credentialIssuer: "https://issuer.com",
            credentialConfigurationIds: ["config"],
            grants: CredentialOfferGrants(preAuthorizedGrant: nil, authorizationCodeGrant: AuthorizationCodeGrant(issuerState: nil, authorizationServer: nil))
        )

        let issuerService = MockIssuerMetadataService()
        issuerService.resultToReturn = makeMinimalIssuerMetadataResult()

        let authCodeFlowService = MockAuthorizationCodeFlowService()
        authCodeFlowService.responseToReturn = makeMinimalCredentialResponse()

        let handler = CredentialOfferHandler(
            credentialOfferService: offerService,
            issuerMetadataService: issuerService,
            preAuthFlowService: MockPreAuthFlowService(),
            authorizationCodeFlowService: authCodeFlowService
        )

        let result = try await handler.downloadCredentials(
            credentialOffer: "offer",
            clientMetadata: ClientMetaData(clientId: "id", redirectUri: "uri"),
            getTxCode: { _,_,_ in "tx-code" },
            getProofJwt: { _, _, _, _ in "jwt" },
            getAuthCode: { _ in "auth-code" }
        )

       
        XCTAssertTrue(authCodeFlowService.didCallRequestCredentials)
    }

    func testTrustCheckBlocksWhenRejected() async {
        let offerService = MockCredentialOfferService()
        offerService.offerToReturn = CredentialOffer(
            credentialIssuer: "https://issuer.com",
            credentialConfigurationIds: ["config"],
            grants: CredentialOfferGrants(preAuthorizedGrant: PreAuthorizedCodeGrant(preAuthorizedCode: "test", txCode: nil, authorizationServer: nil, interval: nil), authorizationCodeGrant: nil)
        )

        let issuerService = MockIssuerMetadataService()
        issuerService.resultToReturn = makeMinimalIssuerMetadataResult()

        let preAuthFlowService = MockPreAuthFlowService()
        preAuthFlowService.responseToReturn = makeMinimalCredentialResponse()

        let handler = CredentialOfferHandler(
            credentialOfferService: offerService,
            issuerMetadataService: issuerService,
            preAuthFlowService: preAuthFlowService,
            authorizationCodeFlowService: MockAuthorizationCodeFlowService()
        )

        do {
            _ = try await handler.downloadCredentials(
                credentialOffer: "offer",
                clientMetadata: ClientMetaData(clientId: "id", redirectUri: "uri"),
                getTxCode: { _,_,_ in "tx-code" },
                getProofJwt: { _, _, _, _ in "jwt" },
                getAuthCode: { _ in "auth-code" },
                onCheckIssuerTrust: { _ in false }
            )
            XCTFail("Expected OfferFetchFailedException")
        } catch let error as OfferFetchFailedException {
            XCTAssertTrue(error.message.contains("Issuer not trusted by user"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testThrowsWhenNoValidGrant() async {
        let offerService = MockCredentialOfferService()
        offerService.offerToReturn = CredentialOffer(
            credentialIssuer: "https://issuer.com",
            credentialConfigurationIds: ["config"],
            grants: CredentialOfferGrants(preAuthorizedGrant: nil, authorizationCodeGrant: nil)
        )

        let issuerService = MockIssuerMetadataService()
        issuerService.resultToReturn = makeMinimalIssuerMetadataResult()

        let handler = CredentialOfferHandler(
            credentialOfferService: offerService,
            issuerMetadataService: issuerService,
            preAuthFlowService: MockPreAuthFlowService(),
            authorizationCodeFlowService: MockAuthorizationCodeFlowService()
        )

        do {
            _ = try await handler.downloadCredentials(
                credentialOffer: "offer",
                clientMetadata: ClientMetaData(clientId: "id", redirectUri: "uri"),
                getTxCode: { _,_,_ in "tx-code" },
                getProofJwt: { _, _, _, _ in "jwt" },
                getAuthCode: { _ in "auth-code" }
            )
            XCTFail("Expected OfferFetchFailedException")
        } catch let error as OfferFetchFailedException {
            XCTAssertTrue(error.message.contains("supported grant type"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
