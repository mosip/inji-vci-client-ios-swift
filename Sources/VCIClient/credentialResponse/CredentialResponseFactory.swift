import Foundation

protocol CredentialResponseFactoryProtocol {
    static func createCredentialResponse(formatType: CredentialFormat, response: Data) throws -> CredentialResponse?
}

extension CredentialResponseFactoryProtocol{
    static func createCredentialResponse(formatType: CredentialFormat, response: Data) throws -> CredentialResponse? {
        switch formatType{
        case .ldp_vc:
            return try LdpVcCredentialResponseFactory().constructResponse(response: response)
        case .mso_mdoc:
            return try MsoMdocCredentialResponseFactory().constructResponse(response: response)
        }
    }
}

class CredentialResponseFactory: CredentialResponseFactoryProtocol{
    
}
