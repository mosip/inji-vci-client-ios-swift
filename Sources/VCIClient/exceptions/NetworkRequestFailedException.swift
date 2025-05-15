import Foundation

class NetworkRequestFailedException: VCIClientException {
    init(_ message: String?) {
        super.init(
            code: "VCI-006",
            message: "Download failure occurred as Network request failed, details : \(message ?? "")"
        )
    }
}
