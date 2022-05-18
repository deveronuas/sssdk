import Foundation

class SFAuth {
  var accessToken: String? {
    get {
      return KeychainService.accessToken
    }
    
    set(value) {
      KeychainService.accessToken = value
    }
  }
  
  var refreshToken: String? {
    get {
      return KeychainService.refreshToken
    }
    
    set(value) {
      KeychainService.refreshToken = value
    }
  }
  
  var accessTokenExpiryDate: Date? {
    get {
      return KeychainService.accessTokenExpiryDate
    }
    
    set(value) {
      KeychainService.accessTokenExpiryDate = value
    }
  }
  
  var bearerToken: String {
    return "Bearer \(self.accessToken ?? "")"
  }
  
  var isAuthenticated: Bool {
    return accessToken != nil && refreshToken != nil
  }
  
  var isAccessTokenValid: Bool {
    guard self.accessToken != nil else { return false }
    guard let expiry = self.accessTokenExpiryDate else { return false }
    
    // TODO: check if this should be compared to a time in the future (eg. 20 sec) to allow for network latency
    return expiry > Date.now
  }
  
  func reset() {
    KeychainService.clearAll()
  }
  
  /// Fetches a new access token only if it is already expired and stores it to Keychain
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  ///     - completionHandler: The block returns no value and takes the following parameter:
  ///         - error: An error object that contains information about a problem, or nil if the request completed successfully.
  ///
  /// This will also call `interospectAccessToken` to reset the expiry
  func refreshAccessTokenIfNeeded(config: SFConfig, completionHandler: @escaping ((String, Error?) -> Void)) {
    guard !self.isAccessTokenValid else {
      completionHandler(self.bearerToken, nil)
      return
    }
    
    self.refreshAccessToken(config: config) { error in
      if let error = error {
        completionHandler("", error)
        return
      }
      
      completionHandler(self.bearerToken, nil)
    }
  }
  
  /// Fetches a new access token and stores it to Keychain
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  ///     - completionHandler: The block returns no value and takes the following parameter:
  ///         - error: An error object that contains information about a problem, or nil if the request completed successfully.
  ///
  /// This will also call `interospectAccessToken` to reset the expiry
  func refreshAccessToken(config: SFConfig, completionHandler: @escaping ((Error?) -> Void)) {

    guard let refreshToken = self.refreshToken else {
      completionHandler(SSSDKError.authNoRefreshTokenError)
      return
    }
    
    let params: String = "grant_type=refresh_token" +
    "&client_id=\(config.clientId)" +
    "&refresh_token=\(refreshToken)" +
    "&client_secret=\(config.clientSecret)"

    let url = try! URLBuilder.refreshTokenURL(urlString: config.host)
    let request = URLRequestBuilder
      .request(with:
                URLRequestConfig(url: url,
                                 params: params.data(using: .utf8),
                                 httpMethod:.post,
                                 contentType: .urlEncoded))

    let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
      guard let response = response as? HTTPURLResponse else {return}

      if (200...299).contains(response.statusCode) {
        guard let data = data else { return }
        do {
          let decoder = JSONDecoder()
          decoder.dateDecodingStrategy = .secondsSince1970
          let responseData = try decoder.decode(RefreshTokenResponse.self, from: data)

          self.accessToken = responseData.accessToken
          self.interospectAccessToken(config: config, completionHandler: completionHandler)
        } catch {
          completionHandler(error)
        }
      } else {
        completionHandler(error)
      }
    })

    task.resume()
  }
  
  ///  To check the current state of an OAuth 2.0 access token and store expiry it to Keychain
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  ///     - completionHandler: The block returns no value and takes the following parameter:
  ///         - error: An error object that contains information about a problem, or nil if the request completed successfully.
  ///
  /// This method fetches the meta information, from salesforce, surrounding the access token.
  /// Including whether this token is currently active, expiry, originally issued
  func interospectAccessToken(config: SFConfig, completionHandler: @escaping ((Error?) -> Void)) {

    let url = try! URLBuilder.introspectURL(urlString: config.host)

    let params = "token=\(self.accessToken!)" +
    "&client_id=\(config.clientId)" +
    "&client_secret=\(config.clientSecret)" +
    "&token_type_hint=access_token"

    let request = URLRequestBuilder
      .request(with:
                URLRequestConfig(url: url,
                                 params: params.data(using: .utf8),
                                 httpMethod: .post,
                                 contentType: .urlEncoded))

    let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
      guard let response = response as? HTTPURLResponse else {return}
      
      if (200...299).contains(response.statusCode) {
        guard let data = data else { return }
        do {
          let decoder = JSONDecoder()
          let responseData = try decoder.decode(IntrospectResponse.self, from: data)

          let expiryDate = Date(timeIntervalSince1970: TimeInterval(responseData.accessTokenExpiryDate))
          self.accessTokenExpiryDate = expiryDate

          completionHandler(nil)
        } catch {
          completionHandler(error)
        }
      } else {
        completionHandler(error)
      }
    })

    task.resume()
  }
}
