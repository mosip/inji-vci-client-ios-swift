import Foundation

class MsoMdocCredentialResponseFactory: CredentialResponseFactoryProtocol {
    func constructResponse(response: Data) throws -> CredentialResponse? {
        let logTag = Util.getLogTag(className: String(describing: type(of: self)))
        do{
            let vc = try JSONDecoder().decode(MsoMdocCredentialResponse.self, from: response)
            return vc
        }
        catch {
            print(logTag,"error occurred while parsing mso_mdoc data - \(error.localizedDescription)")
            throw DownloadFailedError.decodingResponseFailed
        }
    }
}

