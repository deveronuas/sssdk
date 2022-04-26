import Foundation
import SwiftUI

@available(macOS 10.15, *)
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

  public func configure(host: String, redirectUri: String, clientId: String, clientSecret: String) {
    self.host = host
    self.redirectUri = redirectUri
    self.clientId = clientId
    self.clientSecret = clientSecret
  }

  public func login() throws -> some View {
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

  public func logout() {
    KeychainStore.clearAll()
  }

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
      return // TODO: Return / throw an intelligent error
    }
    guard let refreshToken = KeychainStore.refreshToken else { return }
    
    WebServices.shared.fetchData(host: host, clientId: clientId, clientSecret: clientSecret, refreshToken: refreshToken, accessToken: accessToken, query: query) { data in
      completionHandler(data)
    }
  }
}
