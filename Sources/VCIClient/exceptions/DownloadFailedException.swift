import Foundation

class DownloadFailedException: VCIClientException {
    init(_ message: String?) {
        super.init(
            code: "VCI-009",
            message: "Failed to download Credential: \(message ?? "")"
        )
    }
}
