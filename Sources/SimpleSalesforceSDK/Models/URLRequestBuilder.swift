import Foundation

public struct RequestConfig {
  var url: URL
  var params: Data? = nil
  var method = HTTPMethod.post
  var contentType = RequestContentType.urlEncoded
  var bearerToken: String? = nil
  
  enum HTTPMethod: String {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace = "TRACE"
    case patch = "PATCH"
  }
  
  enum RequestContentType: String {
    case json = "application/json"
    case urlEncoded = "application/x-www-form-urlencoded"
  }
}

public struct URLRequestBuilder {
  
  ///  Builds requests based on provided config
  /// - Parameters:
  ///     - config: Configuration for the request.
  /// - Returns: returns URLRequest for requested URLRequestConfig.
  public static func request(with config: RequestConfig) -> URLRequest {

    var request = URLRequest(url: config.url)
    request.httpMethod = config.method.rawValue
    request.setValue(config.contentType.rawValue,
                     forHTTPHeaderField: "Content-Type")
    
    if let bearerToken = config.bearerToken {
      request.setValue(bearerToken, forHTTPHeaderField: "Authorization")
    }
    if let params = config.params {
      request.httpBody = params
    }
    return request
  }

}
