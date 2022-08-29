import Foundation

/// This class handles the communication with Salesforce API
/// For more information read
/// [Salesforce article on OAuth 2.0 flow](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_flows.htm&type=5)
class WebService {
  
  /// Requests the data using SOQL Query from the salesforce
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  ///     - auth: The Salesforce authentication.
  ///     - query: SOQL query to fetch the data.
  ///     - shouldRetry: If true, the request will be retried on a 401 auth error from Salesforce after attemting a refresh of access token
  /// - Returns: If the fetch succeeds `Data` from salesforce is returned
  static func fetchData(config: SFConfig, auth: SFAuth, query: String, shouldRetry: Bool = true) async throws -> Data? {
    try await auth.refreshAccessTokenIfNeeded(config: config)

    let fetchUrl = try URLBuilder.fetchDataURL(config: config, query: query)
    let requestConfig = RequestConfig(url: fetchUrl, params: nil, method: .get, bearerToken: auth.bearerToken)
    let request = URLRequestBuilder.request(with: requestConfig)

    let (data, statusCode) = try await WebService.makeRequest(request, ignore401: true)
    if shouldRetry && statusCode == 401 {
      try await auth.refreshAccessToken(config: config)
      return try await fetchData(config: config, auth: auth, query: query, shouldRetry: false)
    } else {
      return data
    }
  }

  /// Updates the data using sObject Rows resource.
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  ///     - auth: The Salesforce authentication.
  ///     - id: Record id to update record.
  ///     - objectName: object name to update record.
  ///     - fieldUpdates: Update record data.
  ///     - shouldRetry: If true, the request will be retried on a 401 auth error from Salesforce after attemting a refresh of access token
  static func updateRecord(
    config: SFConfig,
    auth: SFAuth,
    id: String,
    objectName: String,
    fieldUpdates: [String: Any],
    shouldRetry: Bool = true
  ) async throws {
    try await auth.refreshAccessTokenIfNeeded(config: config)

    let jsonData = try JSONSerialization.data(withJSONObject: fieldUpdates, options: .prettyPrinted)
    let fetchUrl = try URLBuilder.updateDataURL(config: config, objectName: objectName, id: id)
    let requestConfig = RequestConfig(url: fetchUrl,
                                      params: jsonData,
                                      method: .patch,
                                      contentType: .json,
                                      bearerToken: auth.bearerToken)
    let request = URLRequestBuilder.request(with: requestConfig)

    let (_, statusCode) = try await WebService.makeRequest(request, ignore401: true)
    if statusCode == 401 && shouldRetry {
      try await auth.refreshAccessToken(config: config)
      try await updateRecord(
        config: config,
        auth: auth,
        id: id,
        objectName: objectName,
        fieldUpdates: fieldUpdates,
        shouldRetry: false // retry only once
      )
    } else {
      return
    }
  }

  // MARK: - Utilities

  static func makeRequest(_ request: URLRequest, ignore401: Bool = false) async throws -> (Data, Int) {
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw SSSDKError.notOk(desc: "no response")
    }

    let statusCode = httpResponse.statusCode
    guard statusCode >= 200 && statusCode < 299 || (ignore401 && statusCode == 401) else {
      if let updateFailedResponse =
          decodeError(data: data, type: [UpdateFailedError].self) {

        print(updateFailedResponse)
        throw SSSDKError.updateFailed(jsonData: String(decoding: data, as: UTF8.self))
      } else if let authRefreshTokenExpiredResponse =
                  decodeError(data: data, type: ResponseError.self) {

        print(authRefreshTokenExpiredResponse)
        throw SSSDKError.authRefreshTokenExpiredError
      }

      throw SSSDKError.notOk(desc: String(decoding: data, as: UTF8.self))
    }
    
    return (data, statusCode)
  }

  static func decodeError <T: Decodable> (data: Data, type: T.Type) -> T? {
    let decoder = JSONDecoder()
    do {
      let response = try decoder.decode(type.self, from: data)
      return response
    } catch {
      print("\(type)")
      print("error while decoding the data")
      return nil
    }
  }

}
