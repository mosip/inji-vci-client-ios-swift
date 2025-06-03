import Foundation

class OfferFetchFailedException: VCIClientException {
    init(_ message: String?) {
        super.init(
            code: "VCI-008",
            message: "Failed to fetch credential offer: \(message ?? "")"
        )
    }
}
