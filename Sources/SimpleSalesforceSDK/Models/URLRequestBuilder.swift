import Foundation

public struct URLRequestConfig {
  var url: URL
  var params: Data?
  var bearerToken: String?
  var httpMethod = HTTPMethod.get
  var contentType = CONTENTTYPE.urlEncoded

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
  
  enum CONTENTTYPE: String {
    case json = "application/json"
    case urlEncoded = "application/x-www-form-urlencoded"
  }
}

public struct URLRequestBuilder {
  ///  Creates URL for updateData api
  /// - Parameters:
  ///     - requestConfig: The URLRequestConfig instance’s configuration.
  /// - Returns: returns URLRequest for requested URLRequestConfiguration.
  public static func request(with config: URLRequestConfig) -> URLRequest {

    var request = URLRequest(url: config.url)
    request.httpMethod = config.httpMethod.rawValue
    request.setValue(config.contentType.rawValue,
                     forHTTPHeaderField: "Content-Type")
    
    if let bearerToken = config.bearerToken {
      request.setValue(bearerToken, forHTTPHeaderField: "Authorization")
    }
    if let params =  config.params {
      request.httpBody = params
    }
    return request
  }
}
