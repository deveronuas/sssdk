import Foundation
import SwiftUI
import SwiftKeychainWrapper

@available(macOS 10.15, *)
@available(iOS 14.0, *)
public class SSSDK {
  public static let shared = SSSDK()
  private var host = ""
  private var redirectUri = ""
  private var clientId = ""
  private var clientSecret = ""

  public func configure(host: String, redirectUri: String, clientId: String, clientSecret: String){
    KeychainWrapper.standard.set(host, forKey:"SSSDK_host")
    KeychainWrapper.standard.set(clientId, forKey:"SSSDK_clientId")
    KeychainWrapper.standard.set(clientSecret, forKey:"SSSDK_clientSecret")
    self.host = host
    self.redirectUri = redirectUri
    self.clientId = clientId
    self.clientSecret = clientSecret
  }

  public func login() -> some View{
    let url = URL(string: "\(host)/oauth2/authorize?" +
                  "response_type=token" +
                  "&client_id=\(clientId)" +
                  "&redirect_uri=\(redirectUri)" +
                  "&mystate=mystate")!

    return LogInView(url: url)
  }

  public func handleAuthRedirect(urlReceived: URL){
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

        KeychainWrapper.standard.set(accessToken, forKey:"SSSDK_accessToken")
        KeychainWrapper.standard.set(refreshToken, forKey:"SSSDK_refreshToken")
      }
    }
  }

  public func logout(){
    KeychainWrapper.standard.removeObject(forKey:"SSSDK_accessToken")
    KeychainWrapper.standard.removeObject(forKey:"SSSDK_accessTokenExpiryDate")
    KeychainWrapper.standard.removeObject(forKey:"SSSDK_refreshToken")
    KeychainWrapper.standard.removeObject(forKey:"SSSDK_host")
    KeychainWrapper.standard.removeObject(forKey:"SSSDK_clientId")
    KeychainWrapper.standard.removeObject(forKey:"SSSDK_clientSecret")
  }

  public func refershAccessToken() {
    WebServices.shared.refreshAccessToken()
  }

  public func fetchData(by query: String, completionHandler: ((Data) -> Void)?) {
    WebServices.shared.fetchData(by: query){ data in
      completionHandler!(data)
    }
  }
}
