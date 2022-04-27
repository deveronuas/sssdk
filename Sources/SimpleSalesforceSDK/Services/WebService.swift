import Foundation

/// WebService class handles the networking to the Salesforce API.
/// For More information you can use [Salesforce article on OAuth 2.0 flow]:(https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_flows.htm&type=5)

class WebService {
  /// Default WebService access
  static let shared = WebService()
  
  private init() {}

  /// Requests the data using SOQL Query from the salesforce database.
  func fetchData(host: String, clientId: String, clientSecret: String, refreshToken: String, accessToken: String, query: String, completionHandler: @escaping ((Data?) -> Void)) {

    let bearerAccessToken = "Bearer \(accessToken)"
    let url = "\(host)/data/v54.0/query/?q="
    let fetchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

    guard let fetchUrl = URL(string: "\(url)\(fetchQuery)") else {return}

    var request = URLRequest(url: fetchUrl)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(bearerAccessToken,forHTTPHeaderField: "Authorization")
    // Checks weather the accessToken is expired or not
    guard let expiry = KeychainService.accessTokenExpiryDate, expiry > Date.now else {
      completionHandler(nil)
      return
    }
    
    let task = URLSession.shared.dataTask(with: request , completionHandler: { data, response, error in
      guard let response = response as? HTTPURLResponse else {return}
      if (200...299).contains(response.statusCode){
        if let error = error {
          print(error.localizedDescription)
        } else {
          guard let data = data else { return }
          completionHandler(data)
        }
      }
      else if (400...499).contains(response.statusCode){
        self.refreshAccessToken(host: host, clientId: clientId, clientSecret: clientSecret, refreshToken: refreshToken)
      }
      else {
        if let error = error {
          print(error.localizedDescription)
        }
      }
    })
    task.resume()
  }

  ///  To check the current state of an OAuth 2.0 access or refresh token
  /// - Parameters:
  ///     - host: The Salesforce instance’s endpoint.
  ///     - clientId: Client identifier for the OAuth 2.0 client.
  ///     - clientSecret : Client Secret for the OAuth 2.0 client.
  ///     - accessToken : The access token issued by the authorization server.
  /// - Returns: The meta information surrounding the token, including whether this token is currently active, expiry, originally issued, this token is not to be used before.
  func interospectAccessToken(host: String, clientId: String, clientSecret: String, accessToken: String) {
    guard let url = URL(string:"\(host)/oauth2/introspect") else { return }

    let params = "token=\(accessToken)" +
    "&client_id=\(clientId)" +
    "&client_secret=\(clientSecret)" +
    "&token_type_hint=access_token"

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = params.data(using: .utf8)

    let task = URLSession.shared.dataTask(with: request , completionHandler: { data, response, error in
      guard let response = response as? HTTPURLResponse else {return}

      if let error = error {
        print(error.localizedDescription)
      } else {
        if (200...299).contains(response.statusCode){
          guard let data = data else { return }
          do {
            let decoder = JSONDecoder()
            let responseData = try decoder.decode(IntrospectResponse.self, from: data)
            
            let expiryDate = Date(timeIntervalSince1970: TimeInterval(responseData.accessTokenExpiryDate))
            KeychainService.setAccessTokenExpiryDate(expiryDate)
          } catch {
            print(error.localizedDescription)
          }
        }
      }
    })
    task.resume()
  }
  /// returns the new access token and also requests the information of the access token and stores it to Keychain
  func refreshAccessToken(host: String, clientId: String, clientSecret: String, refreshToken: String) {
    let params : String  = "grant_type=refresh_token" +
    "&client_id=\(clientId)" +
    "&refresh_token=\(refreshToken)"

    guard let url = URL(string: "\(host)/oauth2/token") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = params.data(using: .utf8)

    let task = URLSession.shared.dataTask(with: request , completionHandler: { data, response, error in
      guard let response = response as? HTTPURLResponse else {return}

      if (200...299).contains(response.statusCode){
        if let error = error {
          print(error.localizedDescription)
        }
        else {
          guard let data = data else { return }
          do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let responseData = try decoder.decode(RefreshTokenResponse.self, from: data)
            
            KeychainService.setAccessToken(responseData.accessToken)
            self.interospectAccessToken(host: host, clientId: clientId, clientSecret: clientSecret, accessToken: responseData.accessToken)
          } catch {
            print(error.localizedDescription)
          }
        }
      }
    })
    task.resume()
  }
}
