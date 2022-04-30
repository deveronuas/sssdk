import Foundation
import SwiftUI

@available(iOS 14.0, *)

/// Custom runtime error. Raised when confoguration is missing or invalid.
public enum ConfigurationError: Error {
  case runtimeError(String)
}

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

  private var host: String?
  private var redirectUri: String?
  private var clientId: String?
  private var clientSecret: String?

  private init() {}

  private func confirmConfiguration() throws {
    if host == nil || host == "" ||
        clientId == nil || clientId == "" ||
        clientSecret == nil || clientSecret == "" ||
        redirectUri == nil || redirectUri == "" {
      throw ConfigurationError.runtimeError("SSSDK not configured yet")
    }
  }

  /// Configure the SDK, these values are stored in memory
  /// - Parameters:
  ///     - host: The Salesforce instance’s endpoint (or that of the experience cloud community)
  ///     - redirectUri: The URL where users are redirected after a successful authentication
  ///     - clientId: Client identifier for the OAuth 2.0 client.
  ///     - clientSecret : Client Secret for the OAuth 2.0 client.
  ///
  /// The `redirectUri` should match your app's deeplink URL scheme (e.g. `com.company.yourapp://auth`)
  /// Once the login flow concludes this Uri should launch your app
  /// and you will receive tokens as query parameters.
  /// To setup your URL Scheme:
  ///   1. Go to your project file in Xcode
  ///   2. Select your target, and go to “Info”
  ///   3. Scroll down until you find “URL Types”
  ///   4. Hit the + button, and add your scheme under “URL schemes”
  /// Also, be sure to add this URL to your redirect uri settings in Salesforce's connected app
  public func configure(host: String, redirectUri: String, clientId: String, clientSecret: String) {
    self.host = host
    self.redirectUri = redirectUri
    self.clientId = clientId
    self.clientSecret = clientSecret
  }

  /// Use this method to show a login flow
  /// - Returns: A LoginView SwiftUI view object with the configured host and redirectUri
  /// - Throws: `ConfigurationError.runtimeError` if the singleton is missing the required configuration
  public func loginView() throws -> some View {
    try! confirmConfiguration()
    
    let url = URL(string: "\(host!)/oauth2/authorize?" +
                  "response_type=token" +
                  "&client_id=\(clientId!)" +
                  "&redirect_uri=\(redirectUri!)" +
                  "&mystate=mystate")!

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
  public func handleAuthRedirect(urlReceived: URL) {
    let url = urlReceived.absoluteString
    var urlComponents: URLComponents? = URLComponents(string: url)
    
    if let fragment = urlComponents?.fragment {
      urlComponents?.query = fragment
      if let queryItems = urlComponents?.queryItems {
        let temp = queryItems.reduce(into: [String: String]()) { (result, item) in
          result[item.name] = item.value
        }
        let accessToken = (temp["access_token"] ?? "") as String
        let refreshToken = ((temp["refresh_token"] ?? "") as String)

        KeychainService.setAccessToken(accessToken)
        KeychainService.setRefreshToken(refreshToken)
      }
    }
  }
  
  /// Erases all tokens and expiry date from keychain
  public func logout() {
    KeychainService.clearAll()
  }
  
  /// This method can be called at anytime to refresh the OAuth access token from the server.
  /// It will extract the new `access_token` and store it in memory for use with API calls
  /// - Throws: `ConfigurationError.runtimeError` if the singleton is missing the required configuration
  public func refershAccessToken() throws {
    try! confirmConfiguration()
    
    guard let refreshToken = KeychainService.refreshToken else { return }

    WebService.shared.refreshAccessToken(
      host: host!,
      clientId: clientId!,
      clientSecret: clientSecret,
      refreshToken: refreshToken
    )
  }

  public func fetchData(by query: String, completionHandler: @escaping ((Data?) -> Void)) throws {
    try! confirmConfiguration()
    
    guard let accessToken = KeychainService.accessToken else {
      throw ConfigurationError.runtimeError("Access Token missing")
    }
    
    guard let refreshToken = KeychainService.refreshToken else {
      throw ConfigurationError.runtimeError("Refresh Token missing")
    }
    
    WebService.shared.fetchData(
      host: host!,
      clientId: clientId!,
      clientSecret: clientSecret!,
      refreshToken: refreshToken,
      accessToken: accessToken,
      query: query
    ) { data in
      completionHandler(data)
    }
  }
}
