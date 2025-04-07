import Foundation

public enum TokenExchangeError: Error, LocalizedError {
    case missingPreAuthCode
    case missingTokenEndpoint
    case emptyResponse
    case missingAccessToken
    
    
    public var errorDescription: String? {
        switch self {
        case .missingPreAuthCode:
            return "The pre-authorization code is missing from the request."
        case .missingTokenEndpoint:
            return "The token endpoint URL is not available or incorrectly configured."
        case .emptyResponse:
            return "Received an empty response from the token endpoint."
        case .missingAccessToken:
            return "The response does not contain an access token."
        }
    }
}
