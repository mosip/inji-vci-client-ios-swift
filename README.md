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
.package(url: "https://github.com/mosip/inji-vci-client-ios", from: "0.4.0")
```

##  API Overview

### 1. Request Credential using Credential Offer

```swift
    public func requestCredentialByCredentialOffer(
        credentialOffer: String,
        clientMetadata: ClientMetadata,
        getTxCode: ((_ inputMode: String?, _ description: String?, _ length: Int?) async throws -> String)?,
        authorizeUser: @escaping AuthorizeUserCallback,
        getTokenResponse: @escaping TokenresponseCallback,
        getProofJwt:ProofJwtCallback,
        onCheckIssuerTrust: CheckIssuerTrustCallback = nil,
        downloadTimeoutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis
    ) async throws -> CredentialResponse?
```
#### Example Use
```swift
let credential = try await VCIClient(traceabilityId: "MyApp").requestCredentialByCredentialOffer(
    credentialOffer: offerString,
    clientMetadata: ClientMetaData(clientId: "...", redirectUri: "..."),
    getTxCode: {
        return "user-entered-tx-code"
    },
    authorizeUser: { authorizationUrl in
        return try await startAuthorizationFlow(url: authorizationUrl)
    },
    getTokenResponse: { tokenRequest in 
        return TokenResponse(...)
    },
    getProofJwt: { credentialIssuer, cNonce, proofSigningAlgorithmsSupportedSupported in
        return try await createProofJwt(...)
    },
    onCheckIssuerTrust: { credentialIssuer, issuerDisplay in
        return try await CheckIssuerTrust(...)
    }
)

```

### 2. Request Credential from Trusted Issuer

```swift
    public func requestCredentialFromTrustedIssuer(
        credentialIssuer: String,
        credentialConfigurationId: String,
        clientMetadata: ClientMetadata,
        authorizeUser: @escaping AuthorizeUserCallback,
        getTokenResponse: @escaping TokenresponseCallback,
        getProofJwt:ProofJwtCallback,
        downloadTimeoutInMillis: Int64 = Constants.defaultNetworkTimeoutInMillis
    ) async throws -> CredentialResponse?
```
#### Example Use
```swift
let response = try await VCIClient(traceabilityId: "MyApp").requestCredentialFromTrustedIssuer(
    credentialIssuer: "issuer",
    credentialConfigurationId: "...",
    clientMetadata: ClientMetaData(clientId: "...", redirectUri: "..."),
    authorizeUser: { authorizationUrl in
        return try await startAuthorizationFlow(url: authorizationUrl)
    },
    getTokenResponse: { tokenRequest in 
        return TokenResponse(...)
    },
    getProofJwt: { credentialIssuer, cNonce, proofSigningAlgorithmsSupportedSupported in
        return try await createProofJwt(...)
    }
)

```

#### 🔹 Parameters:

| Param             | Type          | Description                                                                 |
|------------------|---------------|-----------------------------------------------------------------------------|
| `credentialOffer` | `String`      | Offer as embedded JSON string or credentialOffer URI                          |
| `clientMetadata`  | `ClientMetadata` | Contains client ID and redirect URI                                         |
| `getTxCode`       | `(String?,String?,Int?) -> String` | Optional callback function for TX Code (for Pre-Auth flows)                        |
| `getProofJwt`     | `(String, String?, [String]) -> String` | Callback function to prepare proof-jwt for credential request |
| `authorizeUser`     | `(String) -> String` | Handles authorization and returns the code (for Authorization flows)         |
| `onCheckIssuerTrust`     | `((String,[[String: Any]]) -> Bool)?` | Optional parameter to implement user-trust based credential download from issuer         |

---

### 3. ClientMetaData

```swift
public struct ClientMetaData {
    public let clientId: String
    public let redirectUri: String
}
```

### 4. ⚠️ Deprecated: Legacy Credential Request

This method is **deprecated** as of v0.4.0.  
Please use `requestCredentialByCredentialOffer` or `requestCredentialFromTrustedIssuer` instead.

```swift
@available(*, deprecated, message: "This method is deprecated as per the new VCI Client library contract. Use requestCredentialByCredentialOffer() or requestCredentialFromTrustedIssuer()")
public func requestCredential(
    issuerMeta: IssuerMeta,
    proof: Proof,
    accessToken: String
) async throws -> CredentialResponse?
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
| VCI-002   | `DownloadFailedException`    | Failed to download Credential from issuer              |
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

- Credential download flow (credential offer + trusted issuer)
- Proof JWT signing callbacks
- Token exchange and CNonce logic

> See `VCIClientTest` for full coverage

---

## Platform Support

- **Swift:** 5.7+
- **iOS:** 13.0+

Architecture decisions are noted as ADRs [here](https://github.com/mosip/inji-vci-client/tree/master/doc).

Note: The android library is available [here](https://github.com/mosip/inji-vci-client)

---

## Example App

A complete sample app demonstrating credential issuance flows, proof JWT signing, and error handling with `VCIClient` is available here:

[👉 Example iOS App Repository](https://github.com/mosip/inji-vci-client-ios-swift/tree/release-0.4.x/SwiftExample)

- Shows both **Credential Offer** and **Trusted Issuer** flows
- Includes best practices for callbacks and UI integration
- Can be built and run on iOS device only

> Use the example app to quickly get started and see the library in action.

---
