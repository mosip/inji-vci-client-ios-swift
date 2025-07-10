import Foundation

struct LdpCredentialRequestBody: Encodable {
    let format: CredentialFormat
    let credential_definition: CredentialDefinition
    let proof: JWTProof

    init(format: CredentialFormat, credential_definition: CredentialDefinition, proof: JWTProof) {
        self.format = format
        self.credential_definition = credential_definition
        self.proof = proof
    }
}

struct MsoMdocCredentialRequestBody: Encodable {
    let format: CredentialFormat
    let proof: JWTProof
    let doctype: String
    let claims: [String: AnyCodable]?

    init(format: CredentialFormat, doctype: String, claims: [String: AnyCodable]?, proof: JWTProof) {
        self.format = format
        self.doctype = doctype
        self.proof = proof
        self.claims = claims
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
