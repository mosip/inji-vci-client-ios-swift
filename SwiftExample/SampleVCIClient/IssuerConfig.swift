import Foundation

/* Modify according to use case in trusted issuer flow
   KeyTypes supported : Ed25519
   VCFormats supported : ldp_vc
 */


let credentialIssuer = "https://injicertify-mock.qa-inji1.mosip.net"
let credentialConfigurationId = "MockVerifiableCredential"
let clientId = "mpartner-default-mimoto-mock-oidc"
let redirectUri = "io.mosip.residentapp.inji://oauthredirect"
let proxyTokenEndpoint = "https://api.qa-inji1.mosip.net/v1/mimoto/get-token/Mock"
