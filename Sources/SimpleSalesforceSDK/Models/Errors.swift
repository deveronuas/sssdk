import Foundation

/// Custom errors. Raised for various error conditions
public enum SSSDKError: Error {
  case invalidConfigurationError
  case authNoAccessTokenError
  case authNoRefreshTokenError
  case authRefreshFailedError
  case authRefreshTokenExpiredError
  case authIntrospectFailedError
  case notOk(desc: String)
  case noData
  case updateFailed(jsonData: String)
  case invalidUrlError(url: String)
  case duplicateValueError(desc: [SalesforceError])
  case unknown(desc: String)
}

extension SSSDKError: CustomStringConvertible {
  public var description: String {
    switch self {
      case .invalidConfigurationError:
        return "Please check that the SDK has been configured by calling `configure` method."
      case .authNoAccessTokenError:
        return "Missing access token, try refreshing the access token, try login again."
      case .authNoRefreshTokenError:
        return "Missing refresh token, try login again."
      case .authRefreshTokenExpiredError:
        return "Refresh Access token expired, try login again."
      case .authRefreshFailedError:
        return "Refreshing access token failed, try login again."
      case .authIntrospectFailedError:
        return "Introspecting access token failed, try login again."
      case .notOk(let desc):
        return "Server response for this request is not HTTP 200. Error: \(desc)"
      case .noData:
        return "Server responded without any data."
      case .updateFailed(let jsonData):
        return "Updating data on the server failed. Error: \(jsonData)"
      case .invalidUrlError(let url):
        return "The provided URL (\(url)) is invalid"
      case .duplicateValueError(let desc)
        return "\(desc.description)"
      case .unknown(let desc):
        return desc
    }
  }
}

extension SSSDKError: LocalizedError {
  public var errorDescription: String? {
    switch self {
      case .invalidConfigurationError:
        return NSLocalizedString(self.description, comment: "Configuration Error")
      case .authNoAccessTokenError:
        return NSLocalizedString(self.description, comment: "Access Token Not Found")
      case .authNoRefreshTokenError:
        return NSLocalizedString(self.description, comment: "Refresh Token Not Found")
      case .authRefreshFailedError:
        return NSLocalizedString(self.description, comment: "Refresh Failure")
      case .authIntrospectFailedError:
        return NSLocalizedString(self.description, comment: "Introspect Failure")
      case .authRefreshTokenExpiredError:
        return NSLocalizedString(self.description, comment: "Refresh Access Token Expired")
      case .notOk:
        return NSLocalizedString(self.description, comment: "Non 200 Server Response")
      case .noData:
        return NSLocalizedString(self.description, comment: "Empty Data Response")
      case .updateFailed(_):
        return NSLocalizedString(self.description, comment: "Update Data Failure")
      case .invalidUrlError:
        return NSLocalizedString(self.description, comment: "Invalid url")
      case .duplicateValueError:
        return NSLocalizedString(self.description, comment: "Duplicate value error")
      case .unknown(let desc):
        return NSLocalizedString(desc, comment: "Unexpected Error")
    }
  }
}

struct ResponseError: Decodable {
  var error: String
  var errorDescription: String


  enum CodingKeys: String, CodingKey {
    case error
    case errorDescription = "error_description"
  }
}

struct SalesforceError: Decodable {
  var message: String
  var errorCode: String
  var fields: [String]
}
