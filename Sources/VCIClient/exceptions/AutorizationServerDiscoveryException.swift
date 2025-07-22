import Foundation

class AutorizationServerDiscoveryException: VCIClientException {
    init(_ message: String?) {
        super.init(
            code: "VCI-001",
            message: "Failed to discover authorization server  : \(message ?? "")"
        )
    }
}
