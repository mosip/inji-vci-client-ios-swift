import Foundation

class InvalidDataProvidedException: VCIClientException {
    init(_ message: String?) {
        super.init(
            code: "VCI-004",
            message: "Required details not provided : \(message ?? "")"
        )
    }
}
