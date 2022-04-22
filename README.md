# Simple Salesforce SDK

## Goals:
* Usable by any Salesforce User
    * Internal as well as Community users
* Allow OAuth2 Login flow
* Takes care of saving tokens in keychain
* Allows for fetching any SOQL Query
    * V2: Allow full CRUD + Upsert any Salesforce data
* Auto refreshes access token when it expires

## Auth Methods

### configure
Saves configuration data in memory, of a shared instance
```
SSSDK.shared.configure(host:, redirectUri:, clientId:, clientSecret:)
```

### login
Shows a login popup with the configured host
```
SSSDK.shared.login()
```

### handleAuthRedirect
This method should be called in your app's handler for the auth redirect URI. It will extract the `access_token`, `refresh_token` and save them to keychain. It also uses Salesforce's introspection endpoint to fetch and store the `expiry` of the `access_token` and saves it to keychain.
```
SSSDK.shared.handleAuthRedirect(urlReceived:)
```

### logout
Erases `access_token`, `refresh_token` and `expiry` data from keychain
```
SSSDK.shared.logout()
```

### refershAccessToken
Refreshes the `access_token`, then updates the keychain. It also uses Salesforce's introspection endpoint to fetch and store the `expiry` of the `access_token` and saves it to keychain.
```
SSSDK.shared.refershAccessToken()
```

## Data Methods

All methods below will try and refresh the `access_token` if they receive a 401 response from the server. If the refresh fails, we logout.

### fetchData
Fetches raw data and returns JSON, 

```
SSSDK.shared.fetchData(by query:)
```

