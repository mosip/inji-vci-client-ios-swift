import Foundation

public class CredentialOfferService {
    private let session: NetworkManager

    public init(session: NetworkManager = NetworkManager.shared) {
        self.session = session
    }

    func fetchCredentialOffer(_ credentialOfferData: String) async throws -> CredentialOffer {
        let normalized = credentialOfferData.replacingOccurrences(of: "openid-credential-offer://?", with: "openid-credential-offer://dummy?")

        guard let url = URL(string: normalized),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            throw OfferFetchFailedException("Invalid credential offer format")
        }

        let queryParams = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value ?? "") })

        if let encoded = queryParams["credential_offer"] {
            return try handleByValueOffer(encodedOffer: encoded)
        } else if let uri = queryParams["credential_offer_uri"] {
            return try await handleByReferenceOffer(url: uri)
        } else {
            throw OfferFetchFailedException("Missing 'credential_offer' or 'credential_offer_uri'")
        }
    }

    func handleByValueOffer(encodedOffer: String) throws -> CredentialOffer {
        guard let decoded = encodedOffer.removingPercentEncoding else {
            throw OfferFetchFailedException("Invalid json")
        }
        return try parseCredentialOffer(json: decoded)
    }

    func handleByReferenceOffer(url: String) async throws -> CredentialOffer {
        guard let requestURL = URL(string: url),
              requestURL.scheme != nil,
              requestURL.host != nil else {
            throw OfferFetchFailedException("Invalid credential_offer_uri")
        }

        // Use your NetworkManager to send the request
        let response = try await session.sendRequest(
            url: url,
            method: .get,
            headers: ["Accept": "application/json"]
        )

        guard !response.body.isEmpty else {
            throw OfferFetchFailedException("Credential offer response was empty.")
        }

        return try parseCredentialOffer(json: response.body)
    }

    private func parseCredentialOffer(json: String) throws -> CredentialOffer {
        guard let data = json.data(using: .utf8) else {
            throw OfferFetchFailedException("Invalid json")
        }

        let decoder = JSONDecoder()
        let offer = try decoder.decode(CredentialOffer.self, from: data)
        try CredentialOfferValidator.validate(offer)
        return offer
    }
}
