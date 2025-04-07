import Foundation

public struct CredentialOfferService {
    private let session: NetworkSession

    public init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }

    public func handleByValueOffer(encodedOffer: String) throws -> CredentialOffer {
        guard let decoded = encodedOffer.removingPercentEncoding else {
            throw CredentialOfferError.invalidJson
        }

        return try parseCredentialOffer(json: decoded)
    }

    public func handleByReferenceOffer(from urlString: String) async throws -> CredentialOffer {
        guard let url = URL(string: urlString),
              url.scheme != nil,
              url.host != nil else {
            throw CredentialOfferError.fetchFailed("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try await session.data(for: request)

        guard !data.isEmpty else {
            throw CredentialOfferError.emptyResponse
        }

        guard let json = String(data: data, encoding: .utf8) else {
            throw CredentialOfferError.invalidJson
        }

        return try parseCredentialOffer(json: json)
    }

    private func parseCredentialOffer(json: String) throws -> CredentialOffer {
        guard let data = json.data(using: .utf8) else {
            throw CredentialOfferError.invalidJson
        }

        let decoder = JSONDecoder()
        let offer = try decoder.decode(CredentialOffer.self, from: data)
        try CredentialOfferValidator.validate(offer)
        return offer
    }
}
