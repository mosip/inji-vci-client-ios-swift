import Foundation

class IssuerMetadataFetchException: VCIClientException {
    init(_ message: String?) {
        super.init(
            code: "VCI-009",
            message: "Failed to fetch issuerMetadata: \(message ?? "")"
        )
    }
}
