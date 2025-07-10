public enum GrantType: String {
    case preAuthorized = "urn:ietf:params:oauth:grant-type:pre-authorized_code"
    case authorizationCode = "authorization_code"
    case implicit
}
