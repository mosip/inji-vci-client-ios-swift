
# INJI VCI Client
- Request credential to Credential issuer and send the output Credential response

**_Note:_**
_Consumer of this library will be taking the responsibility of processing or parsing the credential for rendering or any other purpose as per requirement_

## Installation
- Clone the repo
- In your swift application go to file > add package dependency > add the  https://github.com/mosip/inji-vci-client-ios-swift.git in git search bar> add package
- Import the library and use

## Supported Credential formats
1. `ldp_Vc`
2. `mso_mdoc`

Refer [here](./Sources/VCIClient/constants/CredentialFormat.swift) for the format constant

## APIs

##### Request Credential

Request for credential from the issuer, and receive the credential response back in string.

```
    let requestCredential = try await VCIClient().requestCredential(issuerMeta: IssuerMeta, proof: Proof, accessToken: String)
```

###### Parameters

| Name        | Type       | Description                                                                    | Sample                                         |
|-------------|------------|--------------------------------------------------------------------------------|------------------------------------------------|
| issuerMeta  | IssuerMeta | struct of the issuer details like audience, endpoint, timeout, type and format | refer "Construction of issuerMetadata" section |
| proofJwt    | Proof      | The proof used for making credential request. Supported proof types : JWT.     | `JWTProof(jwt: proofJWT)`                      |
| accessToken | String     | token issued by providers based on auth code                                   | ""                                             | 

###### Construction of issuerMetadata

1. Format: `ldp_vc`
```
let issuerMeta = IssuerMeta(credentialAudience: CREDENTIAL_AUDIENCE,
                                    credentialEndpoint: CREDENTIAL_ENDPOINT,
                                    downloadTimeoutInMilliseconds: DOWNLOAD_TIMEOUT,
                                    credentialType: CREDENTIAL_TYPES,
                                    credentialFormat: .ldp_vc)
```
2. Format: `mso_mdoc`
```
let issuerMeta = IssuerMeta(credentialAudience: CREDENTIAL_AUDIENCE,
                            credentialEndpoint: CREDENTIAL_ENDPOINT,
                            downloadTimeoutInMilliseconds: DOWNLOAD_TIMEOUT,
                            credentialFormat: .mso_mdoc,
                            docType: DOCTYPE,
                            claims: CLAIMS)
```

###### Exceptions

1. DownloadFailedError is thrown when the credential issuer did not respond with credential response
2. NetworkRequestTimeOutError is thrown when the request is timedout


## More details

An example app is added under [/SwiftExample](./SwiftExample) folder which can be referenced for more details. extract the swift example app out of the library and then follow the installation steps 

## Architecture decisions

Architecture decisions are noted as ADRs [here](https://github.com/mosip/inji-vci-client/tree/master/doc).

Node: The android library is available [here](https://github.com/mosip/inji-vci-client)