import Foundation
import SwiftKeychainWrapper

class WebServices{
  static let shared = WebServices()
  private let host = KeychainWrapper.standard.string(forKey: "SSSDK_host") ?? ""
  private let clientId = KeychainWrapper.standard.string(forKey: "SSSDK_clientId") ?? ""
  private let clientSecret = KeychainWrapper.standard.string(forKey: "SSSDK_clientSecret") ?? ""

  func fetchData(by query: String, completionHandler: ((Data) -> Void)?) {

    guard let accessToken = KeychainWrapper.standard.string(forKey: "SSSDK_accessToken") else{return}

    let bearerAccessToken = "Bearer \(accessToken)"
    let url = "\(host)/data/v54.0/query/?q="
    let fetchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

    guard let fetchUrl = URL(string: "\(url)\(fetchQuery)") else {return}

    var request = URLRequest(url: fetchUrl)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(bearerAccessToken,forHTTPHeaderField: "Authorization")
    let task = URLSession.shared.dataTask(with: request , completionHandler: { data, response, error in

      guard let response = response as? HTTPURLResponse else {return}
      if (200...299).contains(response.statusCode){
        if let error = error {
          print(error.localizedDescription)
        }
        else {
          guard let data = data else { return }
          completionHandler!(data)
          print(String(data: data, encoding: .utf8) as Any)
        }
      }
      else if (400...499).contains(response.statusCode){
        self.refreshAccessToken()
        self.fetchData(by: query, completionHandler: nil)
      }
      else {
        if let error = error {
          print(error.localizedDescription)
        }
      }
    })
    task.resume()
  }

  func interospectAccessToken(){
    guard let url = URL(string:"\(host)/oauth2/introspect") else {return}
    guard let accessToken = KeychainWrapper.standard.string(forKey: "SSSDK_accessToken") else{return}

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
      }
      else {
        if (200...299).contains(response.statusCode){
          guard let data = data else { return }
          do {
            let decoder = JSONDecoder()
            let responseData = try decoder.decode(IntrospectResponse.self, from: data)

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss E, d MMM y"

            let expiryDate = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(responseData.accessTokenExpiryDate)))
            print(expiryDate)
            KeychainWrapper.standard.set(expiryDate, forKey: "SSSDK_accessTokenExpiryDate")
          }catch{
            print(error.localizedDescription)
          }
        }
      }
    })
    task.resume()
  }

  func refreshAccessToken() {


    guard let refreshToken = KeychainWrapper.standard.string(forKey: "SSSDK_refreshToken") else {return}

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
            print(responseData.accessToken)
            KeychainWrapper.standard.set(responseData.accessToken,forKey:"SSSDK_accessToken")

            self.interospectAccessToken()

          }catch{
            print(error.localizedDescription)
          }
        }
      }
    })
    task.resume()
  }
}
