# Simple Salesforce SDK
This is a simplified SDK that can be used as a replacement for Salesforce's connected mobile SDK in your SwiftUI application.

## Contents
- [Goals](#Goals)
- [Requirements](#Requirements)
- [Auth Methods](#Auth-Methods)
  - [configure](#configure)
  - [login](#login)
  - [handleAuthRedirect](#handleAuthRedirect)
  - [logout](#logout)
  - [refershAccessToken](#refershAccessToken)
- [Data Methods](#Data-Methods)
  - [fetchData](#fetchData)
- [Installation](#Installation)
  - [Swift Package Manager](#Swift-Package-Manager)
  - [Xcode](#xcode)


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

## Auth Methods

#### configure
Saves configuration data in memory

!! Required To use the SSSDK framework you must configure its params before calling other methods

```swift
let HOST = "your host url"
let CLIENTID = "your client's id"
let CLIENTSECRET = "your client's secret"
let REDIRECTURI = "your redirect uri"

SSSDK.shared.configure(host: HOST, redirectUri: REDIRECTURI, clientId: CLIENTID, clientSecret: CLIENTSECRET)
```

#### login
Returns login view with the configured host and redirectUri. Most common use case would be to present this page in sheet.

```swift
@State private var launchLoginView = false

var body: some View {
  VStack {
    Button {
      launchLoginView.toggle()
    } label: {
      Text("Login")
    }
    .sheet(isPresented: $launchLoginView) {
      try? SSSDK.shared.login()
    }
  }
}
```

#### handleAuthRedirect
This method should be called in your app's handler for the auth redirect URI. It will extract the `access_token`, `refresh_token` and save them to keychain. It also uses Salesforce's introspection endpoint to fetch and store the `expiry` of the `access_token` and saves it to keychain.

```swift
ContentView()
  .onOpenURL(perform: { url in
    do {
      try SSSDK.shared.handleAuthRedirect(urlReceived: url)
    } catch {
      print(error.localizedDescription)
    }
  })
```

#### logout
Erases `access_token`, `refresh_token` and `expiry` data from keychain

```swift
var body: some View {
  Button{
    SSSDK.shared.logout()
  } label: {
    Text("Logout")
  }.padding(.all)
}
```

#### refershAccessToken
Refreshes the `access_token`, then updates the keychain.
It also uses Salesforce's introspection endpoint to fetch and store the `expiry` of the `access_token` and saves it to keychain.

```swift
var body: some View {
  Button {
    do {
      try SSSDK.shared.refershAccessToken()
    } catch {
      print(error.localizedDescription)
    }
  } label: {
    Text("Refresh Token")
  }.padding(.all)
}
```

## Data Methods

Methods below will try and refresh the `access_token` if they receive a 401 response from the server. If the refresh fails, we logout.

#### fetchData
Fetches raw data and returns JSON data

```swift
let fetchQuery = "SELECT Id FROM Account"

var body: some View {
  Button{
    do {
      try SSSDK.shared.fetchData(by: fetchQuery) { data in
        guard let data = data else { return }
        print(String(decoding: data, as: UTF8.self))
      }
    } catch {
      print(error.localizedDescription)
    }
  } label: {
    Text("Fetch Accounts")
  }.padding(.all)
}
```

## Installation

### Swift Package Manager

Add the following line to the `dependencies` in your [`Package.swift`](https://developer.apple.com/documentation/swift_packages/package) file:

```swift
.package(url: "https://github.com/deveronuas/sssdk.git", .upToNextMajor(from: "2.4.0"))
```

Next, add `sssdk` as a dependency for your targets:

```swift
.target(name: "MyTarget", dependencies: ["sssdk"])
```

Your completed description may look like this:

```swift
// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "MyPackage",
    dependencies: [
        .package(url: https://github.com/deveronuas/sssdk.git, .upToNextMajor(from: "2.4.0"))
    ],
    targets: [
        .target(name: "MyTarget", dependencies: ["sssdk"])
    ]
)
```

### Xcode
Select File \> Swift Packages \> Add Package Dependency, then enter the following URL:

```
https://github.com/deveronuas/sssdk.git
```

For more details, see [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).
