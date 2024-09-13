import Foundation

public protocol CredentialRequestFactoryProtocol{
    func createCredentialRequest(url: URL,
                                 credentialFormat: CredentialFormat,
                                 accessToken: String,
                                 issuer: IssuerMeta,
                                 proofJwt: Proof) throws -> URLRequest
}

class CredentialRequestFactory: CredentialRequestFactoryProtocol{
    static let shared = CredentialRequestFactory()
    func createCredentialRequest(url: URL,
                                 credentialFormat: CredentialFormat,
                                 accessToken: String,
                                 issuer: IssuerMeta,
                                 proofJwt: Proof) throws -> URLRequest {
        switch credentialFormat{
        case .ldp_vc:
            return try validateAndConstructCredentialRequest(credentialRequest: LdpVcCredentialRequest(
                accessToken: accessToken,
                issuerMetaData: issuer,
                proof:  proofJwt as? JWTProof ?? JWTProof(jwt: "")))
        case .mso_mdoc:
            return try validateAndConstructCredentialRequest(credentialRequest: MsoMdocVcCredentialRequest(accessToken: accessToken,
                                                                                                           issuerMetaData: issuer,
                                                                                                           proof:  proofJwt as? JWTProof ?? JWTProof(jwt: "")))
            
        }
    }
    
    func validateAndConstructCredentialRequest(credentialRequest: CredentialRequestProtocol) throws -> URLRequest{
        let issuerMetadataValidatorResult = credentialRequest.validateIssuerMetadata()
        if(issuerMetadataValidatorResult.isValid){
            return try credentialRequest.constructRequest()
        }
        throw DownloadFailedError.invalidDataProvidedException(invalidFields: issuerMetadataValidatorResult.invalidFields.joined())
    }
}
