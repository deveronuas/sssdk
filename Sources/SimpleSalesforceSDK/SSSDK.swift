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

  private func confirmConfiguration() throws {
    if let config = config, !config.isValid {
      throw SSSDKError.invalidConfigurationError
    }
  }

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

  /// Use this method to show a login flow
  /// - Returns: A LoginView SwiftUI view object with the configured host and redirectUri
  /// - Throws: `ConfigurationError.runtimeError` if the singleton is missing the required configuration
  public func loginView() throws -> some View {
    try! confirmConfiguration()
    
    let url = try! URLBuilder.redirectURL(config: config!)

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
  public func handleAuthRedirect(urlReceived: URL, completionHandler: @escaping ((Error?) -> Void)) throws {
    try! confirmConfiguration()
    
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
        self.auth.interospectAccessToken(config: self.config!, completionHandler: completionHandler)
      }
    }
  }

  /// - Returns: This method returns true if user have the access token and refresh token.
  public func isAuthenticated() -> Bool {
    return self.auth.isAuthenticated
  }

  /// Revokes the access token from salesforce and erases all tokens and expiry date from keychain
  /// - Parameters:
  ///     - completionHandler: The block returns no value and takes the following parameter:
  ///         - error: An error object that contains information about a problem, or nil if the request completed successfully.
  /// - Throws: `ConfigurationError.runtimeError` if the singleton is missing the required configuration
  public func logout(completionHandler: @escaping ((Error?) -> Void)) throws {
    try! confirmConfiguration()

    self.auth.revokeAccessToken(config: config!,
                                completionHandler: completionHandler)
    DispatchQueue.main.async {
      self.auth.reset()
    }
  }

  /// This method can be called at anytime to refresh the OAuth access token from the server.
  /// It will extract the new `access_token` and store it in memory for use with API calls
  /// - Parameters:
  ///     - completionHandler: The block returns no value and takes the following parameter:
  ///         - error: An error object that contains information about a problem, or nil if the request completed successfully.
  /// - Throws: `ConfigurationError.runtimeError` if the singleton is missing the required configuration
  public func refershAccessToken(completionHandler: @escaping ((Error?) -> Void)) throws {
    try! confirmConfiguration()

    self.auth.refreshAccessToken(
      config: self.config!,
      completionHandler: completionHandler
    )
  }

  /// Fetches data using SOQL query
  /// - Parameters:
  ///     - query: SOQL query to fetch the data.
  ///     - completionHandler: The block returns no value and takes the following parameter:
  ///         - Data: when data fetch succeeds `data` is the optional Data from the salesforce.
  ///         - Error: An error object that contains information about a problem, or nil if the request completed successfully.
  /// - Throws: `ConfigurationError.runtimeError` if the singleton is missing the required configuration
  public func fetchData(by query: String, completionHandler: @escaping ((Data?, Error?) -> Void))
  throws {
    try! confirmConfiguration()

    WebService.fetchData(
      config: self.config!,
      auth: self.auth,
      query: query,
      completionHandler: completionHandler
    )
  }

  /// Updates salesforce record using sObject
  /// - Parameters:
  ///     - objectName: Object name to update record.
  ///     - objectId: Record id to update record.
  ///     - fieldUpdates: Update record data.
  ///     - completionHandler: The block returns no value and takes the following parameter:
  ///        - error: An error object that contains information about a problem, or nil if the request completed successfully.
  /// - Throws: `ConfigurationError.runtimeError` if the singleton is missing the required configuration.
  public func update(
    objectName: String,
    objectId: String,
    with fieldUpdates: [String:Any],
    completionHandler: @escaping ((Error?) -> Void)
  ) throws {
    try! confirmConfiguration()

    WebService.updateRecord(
      config: self.config!,
      auth: self.auth,
      id: objectId,
      objectName: objectName,
      fieldUpdates: fieldUpdates,
      completionHandler: completionHandler
    )
  }
}
