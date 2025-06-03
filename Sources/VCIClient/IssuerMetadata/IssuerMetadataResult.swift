import Foundation

struct IssuerMetadataResult {
    let issuerMetadata: IssuerMetadata
    let raw: [String: Any?]

    init(issuerMetadata: IssuerMetadata, raw: [String: Any?]) {
        self.issuerMetadata = issuerMetadata
        self.raw = raw
    }
}
