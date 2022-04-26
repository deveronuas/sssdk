import Foundation

class WebServices {
  static let shared = WebServices()
  
  private init() {}
  
  func fetchData(host: String, clientId: String, clientSecret: String, refreshToken: String, accessToken: String, query: String, completionHandler: @escaping ((Data?) -> Void)) {

    let bearerAccessToken = "Bearer \(accessToken)"
    let url = "\(host)/data/v54.0/query/?q="
    let fetchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

    guard let fetchUrl = URL(string: "\(url)\(fetchQuery)") else {return}

    var request = URLRequest(url: fetchUrl)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(bearerAccessToken,forHTTPHeaderField: "Authorization")
    
    guard let expiry = KeychainStore.accessTokenExpiryDate, expiry > Date.now else {
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

  func interospectAccessToken(host: String, clientId: String, clientSecret: String, accessToken: String){
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
            KeychainStore.setAccessTokenExpiryDate(expiryDate)
          } catch {
            print(error.localizedDescription)
          }
        }
      }
    })
    task.resume()
  }

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
            
            KeychainStore.setAccessToken(responseData.accessToken)
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
