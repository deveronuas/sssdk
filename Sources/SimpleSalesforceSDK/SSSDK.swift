import Foundation
import SwiftUI

@available(iOS 14.0, *)

public enum ConfigurationError : Error {
  case runtimeError(String)
}

public class SSSDK {
  public static let shared = SSSDK()
  
  private var host : String?
  private var redirectUri : String?
  private var clientId : String?
  private var clientSecret : String?

  //Saves configuration data in memory, of a shared instance
  public func configure(host: String, redirectUri: String, clientId: String, clientSecret: String) {
    self.host = host
    self.redirectUri = redirectUri
    self.clientId = clientId
    self.clientSecret = clientSecret
  }
// returns login view with the configured host and redirectUri
  public func loginView() throws -> some View {
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
//This method should be called in your app's handler for the auth redirect URI. It will extract the access_token, refresh_token and save them to keychain. It also uses Salesforce's introspection endpoint to fetch and store the expiry of the access_token and saves it to keychain.
  public func handleAuthRedirect(urlReceived: URL) throws {
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

        KeychainStore.setAccessToken(accessToken)
        KeychainStore.setRefreshToken(refreshToken)
      }
    }
  }
//Erases access token, refresh token and expiry date from keychain
  public func logout() {
    KeychainStore.clearAll()
  }
//Refreshes the access_token, then update it in the keychain. It also uses Salesforce's introspection endpoint to fetch and store the expiry of the access_token and saves it to keychain.
  public func refershAccessToken() throws {
    guard let host = host, let clientId = clientId, let clientSecret = clientSecret else {
      throw ConfigurationError.runtimeError("SSSDK not configured yet")
    }
    guard let refreshToken = KeychainStore.refreshToken else { return }
    
    WebServices.shared.refreshAccessToken(host: host, clientId: clientId, clientSecret: clientSecret, refreshToken: refreshToken)
  }

  public func fetchData(by query: String, completionHandler: @escaping ((Data?) -> Void)) throws {
    guard let host = host, let clientId = clientId, let clientSecret = clientSecret else {
      throw ConfigurationError.runtimeError("SSSDK not configured yet")
    }
    
    guard let accessToken = KeychainStore.accessToken else {
      throw ConfigurationError.runtimeError("Access Token missing")
    }
    guard let refreshToken = KeychainStore.refreshToken else { return }
    
    WebServices.shared.fetchData(host: host, clientId: clientId, clientSecret: clientSecret, refreshToken: refreshToken, accessToken: accessToken, query: query) { data in
      completionHandler(data)
    }
  }
}
