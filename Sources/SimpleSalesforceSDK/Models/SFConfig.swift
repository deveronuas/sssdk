import Foundation

public struct SFConfig {
  var host: String
  var redirectUri: String
  var clientId: String
  var clientSecret: String

  var isValid: Bool {
    host != "" &&
      clientId != "" &&
      clientSecret != "" &&
      redirectUri != ""
  }
}
