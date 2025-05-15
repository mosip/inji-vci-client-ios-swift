import Foundation

class NetworkRequestTimeoutException: VCIClientException {
    init(_ message: String?) {
        super.init(
            code: "VCI-007",
            message: "Download failed due to request timeout: \(message ?? "")"
        )
    }
}
