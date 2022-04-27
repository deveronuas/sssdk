import Foundation
import SwiftUI

@available(iOS 14.0, *)
// custom runtime error
public enum ConfigurationError : Error {
  case runtimeError(String)
}

///
/// SSSDK is a class to help to create the OAuth 2.0 user-agent flow,
/// users authorize a mobile app to access data using an embedded browser.
/// This OAuth 2.0 flow can replace the Salesforce's connected mobile SDK,
/// by that you can directly utilize the salesforce API without the Salesforce's connected mobile SDK.
///
public class SSSDK {
  /// Default SSSDK access
  public static let shared = SSSDK()

  // MARK: Representation Properties

  private var host : String?
  private var redirectUri : String?
  private var clientId : String?
  private var clientSecret : String?

  /// Saves configuration data in memory, of a shared instance
  /// - Parameters:
  ///     - host: The Salesforce instance’s endpoint.
  ///     - redirectUri: The URL where users are redirected after a successful authentication.
  ///     - clientId: Client identifier for the OAuth 2.0 client.
  ///     - clientSecret : Client Secret for the OAuth 2.0 client.
  /// - Note:
  ///        For redirectUri you have to create URL scheme.
  ///        This way, any URL with this scheme would start your App.
  ///        To do so, go to your project file in Xcode.
  ///        Select your target, go to “Info,” and scroll down until you find “URL Types.” Hit the + button, and add your scheme under “URL schemes.”
  public func configure(host: String, redirectUri: String, clientId: String, clientSecret: String) {
    self.host = host
    self.redirectUri = redirectUri
    self.clientId = clientId
    self.clientSecret = clientSecret
  }
  /// returns login view with the configured host and redirectUri
  /// throws
  public func loginView() throws -> some View {
    /// checks weather the SSSDK configured or not
    guard let host = host, let clientId = clientId, let redirectUri = redirectUri else {
      throw ConfigurationError.runtimeError("SSSDK not configured yet")
    }
    
    let url = URL(string: "\(host)/oauth2/authorize?" +
                  "response_type=token" +
                  "&client_id=\(clientId)" +
                  "&redirect_uri=\(redirectUri)" +
                  "&mystate=mystate")!

    return LoginView(url: url)
  }
  /// This method should be called in your app's handler for the auth redirect URI. It will extract the access_token, refresh_token and save them to keychain.
  /// - Parameters:
  ///     - urlReceived:  Salesforce redirected callback URL.
  /// - Note:
  ///     SwiftUI 2.0 comes with a new modifier, onOpenURL.This modifier is available in any View.
  ///      Whereas you could simply implement onOpenURL on any View that might need it,
  ///      it’s not a good idea — you’ll most likely be repeating code to handle the deep link,
  ///      that is, to determine the action to be performed for a particular link.
  ///      My proposed solution is to use App to do this handling and use the environment to propagate the link and react to that change accordingly.
  public func handleAuthRedirect(urlReceived: URL) {
    let url = urlReceived.absoluteString
    var urlComponents: URLComponents? = URLComponents(string: url)
    
    if let fragment = urlComponents?.fragment{
      urlComponents?.query = fragment
      if let queryItems = urlComponents?.queryItems{
        let temp = queryItems.reduce(into: [String: String]()) { (result, item) in
          result[item.name] = item.value
        }
        let accessToken = (temp["access_token"] ?? "")  as String
        let refreshToken = ((temp["refresh_token"] ?? "") as String)

        KeychainService.setAccessToken(accessToken)
        KeychainService.setRefreshToken(refreshToken)
      }
    }
  }
  /// Erases access token, refresh token and expiry date from keychain
  public func logout() {
    KeychainService.clearAll()
  }

  public func refershAccessToken() throws {
    /// checks weather the SSSDK configured or not
    guard let host = host, let clientId = clientId, let clientSecret = clientSecret else {
      throw ConfigurationError.runtimeError("SSSDK not configured yet")
    }
    guard let refreshToken = KeychainService.refreshToken else { return }

    /// Refreshes the access_token, then update it in the keychain. It also uses Salesforce's introspection endpoint to fetch and store the expiry of the access_token and saves it to keychain.
    /// - Parameters:
    ///     - host: The Salesforce instance’s endpoint.
    ///     - clientId: Client identifier for the OAuth 2.0 client.
    ///     - clientSecret : Client Secret for the OAuth 2.0 client.
    ///     - refreshToken : The refresh token issued to the client.
    /// - Returns: A new access token to the client.
    WebService.shared.refreshAccessToken(host: host, clientId: clientId, clientSecret: clientSecret, refreshToken: refreshToken)
  }

  public func fetchData(by query: String, completionHandler: @escaping ((Data?) -> Void)) throws {
    ///checks weather the SSSDK configured or not
    guard let host = host, let clientId = clientId, let clientSecret = clientSecret else {
      throw ConfigurationError.runtimeError("SSSDK not configured yet")
    }
    
    guard let accessToken = KeychainService.accessToken else {
      throw ConfigurationError.runtimeError("Access Token missing")
    }
    guard let refreshToken = KeychainService.refreshToken else {
      throw ConfigurationError.runtimeError("Refresh Token missing")
    }
    
    /// Requests the data using SOQL Query from the salesforce database.
    /// - Parameters:
    ///     - host: The Salesforce instance’s endpoint.
    ///     - clientId: Client identifier for the OAuth 2.0 client.
    ///     - clientSecret : Client Secret for the OAuth 2.0 client.
    ///     - refreshToken : The refresh token issued to the client.
    ///     - accessToken : The access token issued by the authorization server.
    ///     - query : SOQL query to fetch the data.
    /// - Returns: Data from the salesforce database.
    WebService.shared.fetchData(host: host, clientId: clientId, clientSecret: clientSecret, refreshToken: refreshToken, accessToken: accessToken, query: query) { data in
      completionHandler(data)
    }
  }
}
