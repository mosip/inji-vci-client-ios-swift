import Foundation

enum CredentialOfferError: Error, LocalizedError,Equatable {
    case invalidOffer(description: String)
    case invalidJson
    case emptyResponse
    case fetchFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidOffer(let description):
            return description
        case .emptyResponse:
            return "Empty response"
        case .invalidJson:
            return "Invalid JSON"
        case .fetchFailed(let message):
            return message
        }
    }
}
