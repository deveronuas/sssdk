import Foundation

public struct URLRequestConfig {
  var url: URL
  var params: Data?
  var httpMethod: String
  var bearerToken: String?
  var contentType: String
}

public struct URLRequestBuilder {
  ///  Creates URL for updateData api
  /// - Parameters:
  ///     - requestConfig: The URLRequestConfig instance’s configuration.
  /// - Returns: returns URLRequest for requested URLRequestConfiguration.
  public static func request(requestConfig: URLRequestConfig) -> URLRequest {

    var request = URLRequest(url: requestConfig.url)
    request.httpMethod = requestConfig.httpMethod
    request.setValue(requestConfig.contentType,
                     forHTTPHeaderField: "Content-Type")

    if let bearerToken = requestConfig.bearerToken {
      request.setValue(bearerToken, forHTTPHeaderField: "Authorization")
    }
    if let params =  requestConfig.params {
    request.httpBody = params
    }

    return request
  }

}
