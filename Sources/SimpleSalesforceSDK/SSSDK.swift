import Foundation
import SwiftUI

@available(iOS 14.0, *)

/// SSSDK is a class to help to create the OAuth 2.0 user-agent flow,
/// users authorize a mobile app to access data using an embedded browser.
/// This OAuth 2.0 flow can replace the Salesforce's connected mobile SDK,
/// by that you can directly utilize the salesforce API without the Salesforce's connected mobile SDK.
///
/// Once authenticated, you can also use this class to make API calls to Salesforce.
public class SSSDK {

  /// SSSDK is a singleton, use this variable to access it's methods
  public static let shared = SSSDK()

  // MARK: Representation Properties

  private var config: SFConfig?
  private var auth: SFAuth = SFAuth()
  
  private init() {}

  // MARK: - Configuration

  /// Configure the SDK, these values are stored in memory
  /// - Parameters:
  ///     - host: The Salesforce instance’s endpoint (or that of the experience cloud community)
  ///     - redirectUri: The URL where users are redirected after a successful authentication
  ///     - clientId: Client identifier for the OAuth 2.0 client.
  ///     - clientSecret : Client Secret for the OAuth 2.0 client.
  ///
  /// The `redirectUri` should match your app's deeplink URL scheme (e.g. `com.company.yourapp://auth/success`)
  /// Once the login flow concludes this Uri should launch your app
  /// and you will receive tokens as query parameters.
  /// To setup your URL Scheme:
  ///   1. Go to your project file in Xcode
  ///   2. Select your target, and go to “Info”
  ///   3. Scroll down until you find “URL Types”
  ///   4. Hit the + button, and add your scheme under “URL schemes”
  /// Also, be sure to add this URL to your redirect uri settings in Salesforce's connected app
  /// NOTE: If you are calling this to configure a new Host etc., make sure to Logout the pervious user (using `logout()` method)
  public func configure(host: String, redirectUri: String, clientId: String, clientSecret: String) {
    self.config = SFConfig(
      host: host,
      redirectUri: redirectUri,
      clientId: clientId,
      clientSecret: clientSecret
    )
  }

  // MARK: - Auth

  /// Use this method to show a login flow
  /// - Returns: A LoginView SwiftUI view object with the configured host and redirectUri
  /// - Throws: `ConfigurationError.runtimeError` if the singleton is missing the required configuration
  public func loginView() throws -> some View {
    let config = try fetchValidConfig()

    let url = try URLBuilder.redirectURL(config: config)

    return LoginView(url: url)
  }

  /// This method should be called within your app's handler for the auth redirect URI.
  /// It will extract the `access_token` and `refresh_token`, by parsing the supplied URL.
  /// Then save them to keychain.
  /// - Parameters:
  ///     - urlReceived: Full URL received by your handler
  ///
  /// SwiftUI 2.0 comes with a new modifier, onOpenURL.This modifier is available to all Views.
  /// Although, you could implement onOpenURL on any View, we recommend against it.
  /// Our recommended solution is to use the `App` to handle the URL and use the environment
  /// observables to propagate and react to that changes accordingly.
  public func handleAuthRedirect(urlReceived: URL) async throws {
    let config = try fetchValidConfig()

    let url = urlReceived.absoluteString
    var urlComponents: URLComponents? = URLComponents(string: url)

    if let fragment = urlComponents?.fragment {
      urlComponents?.query = fragment
      if let queryItems = urlComponents?.queryItems {
        let temp = queryItems.reduce(into: [String: String]()) { (result, item) in
          result[item.name] = item.value
        }

        self.auth.accessToken = (temp["access_token"] ?? "") as String
        self.auth.refreshToken = ((temp["refresh_token"] ?? "") as String)

        try await self.auth.interospectAccessToken(config: config)
      }
    }
  }

  /// This method can be called at anytime to refresh the OAuth access token from the server.
  /// It will extract the new `access_token` and store it in memory for use with API calls
  /// - Throws: `SSSDKError` errors
  public func refershAccessToken() async throws {
    let config = try fetchValidConfig()

    try await self.auth.refreshAccessToken(config: config)
  }

  /// - Returns: This method returns true if the access token and refresh token are saved in the keychain
  public func isAuthenticated() -> Bool {
    return self.auth.isAuthenticated
  }

  /// Revokes the access token from salesforce and erases all tokens and expiry date from keychain
  /// - Throws: `SSSDKError` errors
  public func logout() async throws {
    let config = try fetchValidConfig()
    do {
      try await self.auth.revokeAccessToken(config: config)
      self.auth.reset()
    } catch {
      self.auth.reset()
      throw error
    }
  }

  // MARK: - Data

  /// Fetches data using SOQL query
  /// - Parameters:
  ///     - query: SOQL query to fetch the data.
  /// - Throws: `SSSDKError` errors
  /// - Returns: `Data` results of the query returned by the salesforce server
  public func fetchData(by query: String) async throws -> Data? {
    let config = try fetchValidConfig()

    return try await WebService.fetchData(config: config, auth: self.auth, query: query)
  }

  /// Fetches data using nextRecordsUrl.
  /// - Parameters:
  ///     - nextRecordsUrl:  A string used to retrieve the next set of query results.
  /// - Throws: `SSSDKError` errors
  /// - Returns: `Data` results of the query returned by the salesforce server
  public func fetchData(using nextRecordsUrl: String) async throws -> Data? {
    let config = try fetchValidConfig()

    return try await WebService.fetchData(config: config, auth: self.auth, nextRecordsUrl: nextRecordsUrl)
  }

  /// Updates salesforce record using sObject
  /// - Parameters:
  ///     - objectName: Name of the object to update the record in.
  ///     - objectId: ID of the record to update.
  ///     - fieldUpdates: Data to update the record with.
  /// - Throws: `SSSDKError` errors
  public func update(objectName: String, objectId: String, with fieldUpdates: [String:Any]) async throws {
    let config = try fetchValidConfig()

    try await WebService.updateRecord(
      config: config,
      auth: self.auth,
      id: objectId,
      objectName: objectName,
      fieldUpdates: fieldUpdates
    )
  }

  /// Create record or update existing record (upsert) based on the value of a specified external ID field.
  /// - Parameters:
  ///   - objectName: Name of the object to upsert record into.
  ///   - fieldUpdates: Data for the upserted record.
  ///   - externalIdFieldName: Name of the external field id
  ///   - externalIdFieldValue: Value of the external field id
  /// - Throws: `SSSDKError` errors
  /// - Returns: `Data` results of the query returned by the salesforce server
  public func upsert(objectName: String,
                     fieldUpdates: [String:Any],
                     externalIdFieldName: String,
                     externalIdFieldValue: String) async throws -> Data? {
    let config = try fetchValidConfig()

    return try await WebService.upsertRecord(
      config: config,
      auth: self.auth,
      objectName: objectName,
      externalIdFieldName: externalIdFieldName,
      externalIdFieldValue: externalIdFieldValue,
      fieldUpdates: fieldUpdates
    )
  }

  /// Insert record using sObject
  /// - Parameters:
  ///     - objectName: Name of the object to insert record into.
  ///     - fieldUpdates:  Data for the inserted record.
  /// - Throws: `SSSDKError` errors
  /// - Returns: `Data` results of the query returned by the salesforce server
  public func insert(objectName: String, with fieldUpdates: [String:Any]) async throws -> Data?{
    let config = try fetchValidConfig()

    return try await WebService.insertRecord(
      config: config,
      auth: self.auth,
      objectName: objectName,
      fieldUpdates: fieldUpdates
    )
  }

  // MARK: - Utilities
  private func fetchValidConfig() throws -> SFConfig {
    guard let config = self.config, config.isValid else {
      throw SSSDKError.invalidConfigurationError
    }

    return config
  }
}
