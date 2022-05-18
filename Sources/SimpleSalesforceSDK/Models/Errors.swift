import Foundation

/// Custom errors. Raised for various error conditions
public enum SSSDKError: Error {
  case invalidConfigurationError
  case authNoAccessTokenError
  case authNoRefreshTokenError
  case authRefreshFailedError
  case authIntrospectFailedError
  case invalidUrlError(url: String)
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
      case .authRefreshFailedError:
        return "Refreshing access token failed, try login again."
      case .authIntrospectFailedError:
        return "Introspecting access token failed, try login again."
      case .invalidUrlError(let url):
        return "The provided URL (\(url)) is invalid"
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
      case .invalidUrlError:
        return NSLocalizedString(self.description, comment: "Invalid url")
      case .unknown(let desc):
        return NSLocalizedString(desc, comment: "Unexpected Error")
    }
  }
}
