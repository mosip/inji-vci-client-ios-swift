
# INJI VCI Client
- Request credential to Credential issuer

## Installation
- Clone the repo
- In your swift application go to file > add package dependency > add the  https://github.com/mosip/inji-vci-client-ios-swift.git in git search bar> add package
- Import the library and use

## APIs

##### Request Credential

Request for credential from the issuer, and receive the credential response back in string.

```
    let requestCredential = try await VCIClient().requestCredential(issuerMeta: IssuerMeta, proof: Proof, accessToken: String)
```

###### Parameters

| Name         | Type                               | Description                                                                                                  | Sample                                                                                                  |
|--------------|------------------------------------|--------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| issuerMeta   | IssuerMeta                         | struct of the issuer details like audience, endpoint, timeout, type and format                                                                           | `IssuerMeta(credentialAudience, credentialEndpoint, downloadTimeout, credentialType, credentialFormat)` |
| proofJwt       | Proof | The proof used for making credential request. Supported proof types : JWT. | `JWTProof(jwt: proofJWT)`                                           |
| accessToken  | String                             | token issued by providers based on auth code                                                                 | "" | 

###### Exceptions

1. DownloadFailedError is thrown when the credential issuer did not respond with credential response
2. NetworkRequestTimeOutError is thrown when the request is timedout


## More details

An example app is added under /SwiftExample folder which can be referenced for more details. extract the swift example app out of the library and then follow the installation steps 
