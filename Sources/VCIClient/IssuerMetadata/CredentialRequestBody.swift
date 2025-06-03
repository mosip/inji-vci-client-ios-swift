import Foundation

struct CredentialRequestBody: Encodable {
    let format: CredentialFormat
    let credential_definition: CredentialDefinition
    let proof: JWTProof

    init(format: CredentialFormat, credential_definition: CredentialDefinition, proof: JWTProof) {
        self.format = format
        self.credential_definition = credential_definition
        self.proof = proof
    }
}

struct CredentialDefinition: Codable {
    let context: [String]?
    let type: [String]

    private enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type
    }

    init(context: [String]? = ["https://www.w3.org/2018/credentials/v1"], type: [String]) {
        self.context = context
        self.type = type
    }
}
