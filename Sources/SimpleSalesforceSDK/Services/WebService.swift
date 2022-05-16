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
  ///     - completionHandler: The block returns no value and takes the following parameter:
  ///         - Data: when data fetch succeeds `data` is the optional Data from the salesforce.
  ///         - Error: An error object that contains information about a problem, or nil if the request completed successfully.
  ///     - shouldRetry: If true, the request will be retried on a 401 auth error from Salesforce after attemting a refresh of access token
  static func fetchData(
    config: SFConfig,
    auth: SFAuth,
    query: String,
    completionHandler: @escaping ((Data?, Error?) -> Void),
    shouldRetry: Bool = true
  ) {
    auth.refreshAccessTokenIfNeeded(config: config) { bearerToken, error in
      if error != nil {
        completionHandler(nil, error)
        return
      }
      
      let url = "\(config.host)/data/v54.0/query/?q="
      let fetchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
      
      guard let fetchUrl = URL(string: "\(url)\(fetchQuery)") else {return}
      
      var request = URLRequest(url: fetchUrl)
      request.httpMethod = "GET"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.setValue(bearerToken,forHTTPHeaderField: "Authorization")
      
      guard let expiry = KeychainService.accessTokenExpiryDate, expiry > Date.now else {
        return
      }
      
      let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
        guard let response = response as? HTTPURLResponse else {return}
        if (200...299).contains(response.statusCode) {
          completionHandler(data, nil)
        } else if response.statusCode == 401 && shouldRetry {
          auth.refreshAccessToken(config: config) { error in
            if error != nil {
              completionHandler(nil, error)
              return
            }
            
            fetchData(
              config: config,
              auth: auth,
              query: query,
              completionHandler: completionHandler,
              shouldRetry: false // retry only once
            )
          }
        } else {
          completionHandler(nil, error)
        }
      })
      
      task.resume()
    }
  }

  /// Updates the data using sObject Rows resource.
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  ///     - auth: The Salesforce authentication.
  ///     - id: Record id to update record.
  ///     - objectName: object name to update record.
  ///     - fieldUpdates: Update record data.
  ///     - completionHandler: The block returns no value and takes the following parameter:
  ///         - error: An error object that contains information about a problem, or nil if the request completed successfully.
  ///     - shouldRetry: If true, the request will be retried on a 401 auth error from Salesforce after attemting a refresh of access token
  static func updateRecord(
    config: SFConfig,
    auth: SFAuth,
    id: String,
    objectName: String,
    fieldUpdates: [String: Any],
    completionHandler: @escaping ((Error?) -> Void),
    shouldRetry: Bool = true
  ) {
    auth.refreshAccessTokenIfNeeded(config: config) { bearerToken, error in
      if error != nil {
        completionHandler(error)
        return
      }
      
      let jsonData = try? JSONSerialization.data(
        withJSONObject: fieldUpdates, options: .prettyPrinted)

      let url = "\(config.host)/data/v54.0/sobjects/\(objectName)/\(id)"
      let fetchUrl = URL(string: "\(url)")!

      var request = URLRequest(url: fetchUrl)
      request.httpMethod = "PATCH"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.setValue(bearerToken, forHTTPHeaderField: "Authorization")
      request.httpBody = jsonData

      let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
        let response = response as! HTTPURLResponse

        if response.statusCode == 204 {
          completionHandler(nil)
        } else if response.statusCode == 401 && shouldRetry {
          auth.refreshAccessToken(config: config) { error in
            if error != nil {
              completionHandler(error)
              return
            }
            
            updateRecord(
              config: config,
              auth: auth,
              id: id,
              objectName: objectName,
              fieldUpdates: fieldUpdates,
              completionHandler: completionHandler,
              shouldRetry: false // retry only once
            )
          }
        } else {
          completionHandler(error)
        }
      })

      task.resume()
    }
  }
}
