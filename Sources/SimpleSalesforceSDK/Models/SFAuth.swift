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
  /// This will also call `interospectAccessToken` to reset the expiry
  func refreshAccessTokenIfNeeded(config: SFConfig) async throws {
    guard !self.isAccessTokenValid else { return }

    try await self.refreshAccessToken(config: config)
  }

  /// Fetches a new access token and stores it to Keychain
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  /// This will also call `interospectAccessToken` to reset the expiry
  func refreshAccessToken(config: SFConfig) async throws {
    guard let refreshToken = self.refreshToken else {
      throw SSSDKError.authNoRefreshTokenError
    }

    let params: String = "grant_type=refresh_token" +
    "&client_id=\(config.clientId)" +
    "&refresh_token=\(refreshToken)" +
    "&client_secret=\(config.clientSecret)"

    let url = try URLBuilder.refreshTokenURL(urlString: config.host)
    let requestConfig = RequestConfig(url: url, params: params.data(using: .utf8))
    let request = URLRequestBuilder.request(with: requestConfig)
    do {
      let (data, _) = try await WebService.makeRequest(request)
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .secondsSince1970
      let responseData = try decoder.decode(RefreshTokenResponse.self, from: data)

      self.accessToken = responseData.accessToken
      try await self.interospectAccessToken(config: config)
    } catch SSSDKError.authRefreshTokenExpiredError {
      throw SSSDKError.authRefreshTokenExpiredError
    }
  }

  ///  To check the current state of an OAuth 2.0 access token and store expiry it to Keychain
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  /// This method fetches the meta information, from salesforce, surrounding the access token.
  /// Including whether this token is currently active, expiry, originally issued
  func interospectAccessToken(config: SFConfig) async throws {
    let url = try URLBuilder.introspectURL(urlString: config.host)

    let params = "token=\(self.accessToken!)" +
    "&client_id=\(config.clientId)" +
    "&client_secret=\(config.clientSecret)" +
    "&token_type_hint=access_token"

    let requestConfig = RequestConfig(url: url, params: params.data(using: .utf8))
    let request = URLRequestBuilder.request(with: requestConfig)
    let (data, _) = try await WebService.makeRequest(request)

    let responseData = try JSONDecoder().decode(IntrospectResponse.self, from: data)
    let expiryDate = Date(timeIntervalSince1970: TimeInterval(responseData.accessTokenExpiryDate))
    self.accessTokenExpiryDate = expiryDate
  }
  
  /// Revokes the salesforce access token.
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  ///
  /// This method requests salesforce to invalidate and revoke the access token.
  func revokeAccessToken(config: SFConfig) async throws {
    let url = try URLBuilder.revokeTokenURL(urlString: config.host)
    let params = "token=\(self.accessToken!)"
    let requestConfig = RequestConfig(url: url, params: params.data(using: .utf8))
    let request = URLRequestBuilder.request(with: requestConfig)
    
    let _ = try await WebService.makeRequest(request)
  }
}
