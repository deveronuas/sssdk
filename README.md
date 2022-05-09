# Simple Salesforce SDK
This is a simplified SDK that can be used as a replacement for Salesforce's connected mobile SDK in your SwiftUI application.

## Contents
- [Goals](#Goals)
- [Requirements](#Requirements)
- [Auth Methods](https://github.com/deveronuas/sssdk/wiki/Auth-Methods)
- [Data Methods](https://github.com/deveronuas/sssdk/wiki/Data-Methods)
- [Installation](https://github.com/deveronuas/sssdk/wiki/Installation)
- [Release Process](https://github.com/deveronuas/sssdk/wiki/Development-Process)

## Goals
* Usable by any Salesforce User
    * Internal as well as Community users
* Allow OAuth2 Login flow
* Takes care of saving tokens in keychain
* Allows for fetching any SOQL Query
    * V2: Allow full CRUD + Upsert any Salesforce data
* Auto refreshes access token when it expires

## Requirements
* Xcode 13.3.1
* Swift 5.6
* iOS 15.0+
