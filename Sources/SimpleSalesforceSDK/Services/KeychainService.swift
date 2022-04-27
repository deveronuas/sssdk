import Foundation
import SwiftKeychainWrapper

struct KeychainService {
  static let KEY_ACCESS_TOKEN = "SSSDK_accessToken"
  static let KEY_ACCESS_TOKEN_EXPIRY = "SSSDK_accessTokenExpiryDate"
  static let KEY_REFRESH_TOKEN = "SSSDK_refreshToken"
  
  static var accessToken : String? {
    return KeychainWrapper.standard.string(forKey: KEY_ACCESS_TOKEN)
  }
  
  static var accessTokenExpiryDate : Date? {
    if let dateString = KeychainWrapper.standard.string(forKey: KEY_ACCESS_TOKEN_EXPIRY) {
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm:ss E, d MMM y"
      
      return formatter.date(from: dateString)
    } else {
      return nil
    }
  }
  
  static var refreshToken : String? {
    return KeychainWrapper.standard.string(forKey: KEY_REFRESH_TOKEN)
  }
  
  static func setAccessToken(_ value : String) {
    KeychainWrapper.standard.set(value, forKey: KEY_ACCESS_TOKEN)
  }
  
  static func setAccessTokenExpiryDate(_ value : Date) {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss E, d MMM y"
    
    let expiryDateString = formatter.string(from: value)
    
    KeychainWrapper.standard.set(expiryDateString, forKey: KEY_ACCESS_TOKEN_EXPIRY)
  }
  
  static func setRefreshToken(_ value : String) {
    KeychainWrapper.standard.set(value, forKey: KEY_REFRESH_TOKEN)
  }
  
  static func clearAll() {
    KeychainWrapper.standard.removeObject(forKey: KEY_ACCESS_TOKEN)
    KeychainWrapper.standard.removeObject(forKey: KEY_ACCESS_TOKEN_EXPIRY)
    KeychainWrapper.standard.removeObject(forKey: KEY_REFRESH_TOKEN)
  }
}
