import Foundation

class InvalidPublicKeyException: VCIClientException {
    init(_ message: String?) {
        super.init(
            code: "VCI-005",
            message: "Invalid public key passed $message: \(message ?? "")"
        )
    }
}
