import Foundation

class InvalidAccessTokenException: VCIClientException {
    init(_ message: String?) {
        super.init(
            code: "VCI-003",
            message: "Access token is invalid : \(message ?? "")"
        )
    }
}
