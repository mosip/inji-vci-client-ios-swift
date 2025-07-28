import Foundation

public enum CredentialFormat: String , Codable{
    case ldp_vc = "ldp_vc"
    case mso_mdoc = "mso_mdoc"
    case vc_sd_jwt = "vc+sd-jwt"
}
