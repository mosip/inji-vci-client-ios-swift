import Foundation

public class JWTProof: Proof {
    public var proof_type: String = ProofType.JWT.rawValue
    public var jwt: String

    public init(jwt: String) {
        self.jwt = jwt
    }
}
