# INJI VCI Client iOS Swift

The **Inji VCI Client iOS Swift** is a swift-based library built to simplify credential issuance via [OpenID for Verifiable Credential Issuance (OID4VCI)](https://openid.net/specs/openid-4-verifiable-credential-issuance-1_0-13.html) protocol.  
It supports both **Credential Offer** and **Trusted Issuer** flows, with secure proof handling, PKCE support, and custom error handling.


---

## Features

- Request credentials from OID4VCI-compliant credential issuers
- Supports both:
        - Credential Offer Flow.
        - Trusted Issuer Flow.
- Authorization server discovery for both flows
- PKCE-compliant OAuth 2.0 Authorization Code flow (RFC 7636)
- Automatic CNonce + Proof JWT handling
- Well-defined **exception handling** with `VCI-XXX` error codes
- Support for multiple formats:
        - `ldp_vc`
        - `mso_mdoc`

> ⚠️ Consumer of this library is responsible for processing and rendering the credential after it is downloaded.

---

##  Installation

Add VCIClient to your Swift Package Manager dependencies:

```swift
.package(url: "https://github.com/mosip/inji-vci-client-ios", from: "0.3.0")
```

##  API Overview

### 1. Request Credential using Credential Offer

```swift
let credential = try await VCIClient(traceabilityId: "MyApp").requestCredentialByCredentialOffer(
    credentialOffer: offerString,
    clientMetadata: ClientMetaData(clientId: "...", redirectUri: "..."),
    getTxCode: {
        //for pre-auth (optional)
        return "user-entered-tx-code"
    },
    getProofJwt: { accessToken, cNonce, issuerMeta, credentialConfigurationId in
        return try await createProofJwt(accessToken: accessToken, cNonce: cNonce, issuerMetadata: issuerMeta)
    },
    getAuthCode: { authorizationEndpoint in
        return try await startAuthorizationFlow(url: authorizationEndpoint)
    }
    onCheckIssuerTrust: { issuerMetadata in
        return try await CheckIssuerTrust(issuerMetadata: issuerMetadata)
    }
)

```

### 2. Request Credential from Trusted Issuer

```kotlin
val response = VCIClient(traceabilityId).requestCredentialFromTrustedIssuer(
    IssuerMetadata = metadata,
    clientMetadata = ClientMetadata(clientId, redirectUri),
    getProofJwt = { accessToken, cNonce?, issuerMeta?, configId? -> ... },
    getAuthCode = { authorizationEndpoint -> ... }
)
```

#### 🔹 Parameters:

| Param             | Type          | Description                                                                 |
|------------------|---------------|-----------------------------------------------------------------------------|
| `credentialOffer` | `String`      | Offer as embedded JSON or `credential_offer_uri`                           |
| `clientMetadata`  | `ClientMetadata` | Contains client ID and redirect URI                                         |
| `IssuerMetadata`  | `IssuerMetadata` | Contains Issuer metadata details required for credential request                                         |
| `getTxCode`       | `() -> String` | Optional callback function for TX Code (for Pre-Auth flows)                        |
| `getProofJwt`     | `(String, String?, [String,Any],String -> String` | Callback function to prepare proof-jwt for credential request |
| `getAuthCode`     | `(String) -> String` | Handles authorization and returns the code (for Authorization flows)         |
| `onCheckIssuerTrust`     | `(([String: Any]) -> Bool)?` | Optional parameter to implement user-trust based credential download from issuer         |

---

---

### 3. Constructing `IssuerMetadata`

Supports both `ldp_vc` and `mso_mdoc`.

#### 🔹 LDP VC Format:
```swift
let metadata = IssuerMetadata(
    credentialAudience: "https://issuer.com",
    credentialEndpoint: "https://issuer.com/credential",
    credentialType: ["VerifiableCredential", "ExampleVC"],
    context: ["https://www.w3.org/2018/credentials/v1"],
    credentialFormat: .ldp_vc,
    authorizationServers: ["https://auth.issuer.com"],
    scope: "openid example"
)
```

#### 🔹 MSO mDoc Format:
```swift
let metadata = IssuerMetadata(
    credentialAudience: "https://issuer.com",
    credentialEndpoint: "https://issuer.com/credential",
    doctype: "org.iso.18013.5.1.mDL",
    claims: ["given_name": AnyCodable("John"), "family_name": AnyCodable("Doe")],
    credentialFormat: .mso_mdoc,
    authorizationServers: ["https://auth.issuer.com"]
)

```

---

##  Security Support

-  **PKCE (Proof Key for Code Exchange)** handled internally (RFC 7636)
-  Supports `S256` code challenge method
-  Secure `c_nonce` binding via proof JWTs

---

##  Error Handling

All exceptions thrown by the library are subclasses of `VCIClientException`.  
They carry structured error codes like `VCI-001`, `VCI-002` etc., to help consumers identify and recover from failures.

| Code      | Exception Type                      | Description                                  |
|-----------|-------------------------------------|----------------------------------------------|
| VCI-001   | `AuthServerDiscoveryException`           | Failed to discover authorization server              |
| VCI-002   | `DownloadFailedException`    | Failed to download Credential issuer              |
| VCI-003   | `InvalidAccessTokenException`       | Access token is invalid                   |
| VCI-004   | `InvalidDataProvidedException`         | Required details not provided      |
| VCI-005   | `InvalidPublicKeyException`      | Invalid public key passed metadata              |
| VCI-006   | `NetworkRequestFailedException`         | Network request failed |
| VCI-007   | `NetworkRequestTimeoutException`         | Network request timed-out |
| VCI-008   | `OfferFetchFailedException`         |  Failed  to fetch credentialOffer |
| VCI-009   | `IssuerMetadataFetchException`         | Failed to fetch issuerMetadata|


---

##  Testing

Mock-based tests are available covering:

- Credential download flow (offer + trusted issuer)
- Proof JWT signing callbacks
- Token exchange and CNonce logic

> See `VCIClientTest` for full coverage


Architecture decisions are noted as ADRs [here](https://github.com/mosip/inji-vci-client/tree/master/doc).

Node: The android library is available [here](https://github.com/mosip/inji-vci-client)

