import Foundation

public protocol Proof: Encodable {
    var proof_type: String { get set }
    var jwt: String { get set }
}
