import Foundation
import UIKit

public struct URLBuilder {

  ///  Verifies if URL string has suffix "/" or not, if not then adds suffix "/" at the end of the string
  /// - Parameters:
  ///     - host: The Salesforce instance’s configuration.
  /// - Returns: returns urlString 
  public static func verifyHost(host: String) -> String {
    if !host.hasSuffix("/"){
      return host.appending("/")
    }
    return host
  }

  ///  Creates URL for OAuth2.0 login flow
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  /// - Throws: `SSSDKError.invalidUrlError` if the provided host url is invalid
  /// - Returns: returns URL for OAuth2.0 login flow
  public static func redirectURL(config: SFConfig) throws -> URL {
    let host = verifyHost(host: config.host)

    guard let redirectUrl = URL(string: "\(host)services/oauth2/authorize?" +
                                "response_type=token" +
                                "&client_id=\(config.clientId)" +
                                "&redirect_uri=\(config.redirectUri)")
    else {
      throw (SSSDKError.invalidUrlError(url: host))
    }
    return redirectUrl
  }

  ///  Creates URL for introspect  access token api
  /// - Parameters:
  ///     - urlString: The Salesforce instance’s endpoint (or that of the experience cloud community).
  /// - Throws: `SSSDKError.invalidUrlError` if the provided host url is invalid
  /// - Returns: returns URL for introspect  access token api.
  public static func introspectURL(urlString: String) throws -> URL {
    let host = verifyHost(host: urlString)
    guard let introspectUrl = URL(string: "\(host)services/oauth2/introspect")
    else {
      throw SSSDKError.invalidUrlError(url: host)
    }
    return introspectUrl
  }

  ///  Creates URL for refresh access token api
  /// - Parameters:
  ///     - urlString: The Salesforce instance’s endpoint (or that of the experience cloud community).
  /// - Throws: `SSSDKError.invalidUrlError` if the provided host url is invalid
  /// - Returns: returns URL for refresh access token api.
  public static func refreshTokenURL(urlString: String) throws -> URL {
    let host = verifyHost(host: urlString)
    guard let refreshToneUrl = URL(string: "\(host)services/oauth2/token")
    else {
      throw SSSDKError.invalidUrlError(url: host)
    }
    return refreshToneUrl
  }

  ///  Creates URL for revoke access token api
  /// - Parameters:
  ///     - urlString: The Salesforce instance’s endpoint (or that of the experience cloud community).
  /// - Throws: `SSSDKError.invalidUrlError` if the provided host url is invalid
  /// - Returns: returns URL for introspect  access token api.
  public static func revokeTokenURL(urlString: String) throws -> URL {
    let host = verifyHost(host: urlString)
    guard let revokeTokenUrl = URL(string: "\(host)services/oauth2/revoke")
    else {
      throw SSSDKError.invalidUrlError(url: host)
    }
    return revokeTokenUrl
  }

  ///  Creates URL for fetchData api
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  ///     - query: SOQL query to fetch the data.
  /// - Throws: `SSSDKError.invalidUrlError` if the provided host url is invalid
  /// - Returns: returns URL for fetchData api.
  public static func fetchDataURL(config: SFConfig,
                                  query: String,
                                  isSOQlQuery: Bool = true) throws -> URL {
    let host = verifyHost(host: config.host)
    var url = ""

    if isSOQlQuery {
      url = "\(host)services/data/v54.0/query/?q=" + query
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    } else {
      url = "\(host)services/data/v54.0/query/\(query)"
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }
    guard let fetchUrl = URL(string: url)
    else {
      throw SSSDKError.invalidUrlError(url: host)
    }
    return fetchUrl
  }

  ///  Creates URL for updateData api
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  ///     - objectName: Object name to update record.
  ///     - id: Record id to update record.
  /// - Throws: `SSSDKError.invalidUrlError` if the provided host url is invalid
  /// - Returns: returns URL for updateData api.
  public static func updateDataURL(config: SFConfig,
                                   objectName: String,
                                   id: String) throws -> URL {
    let host = verifyHost(host: config.host)
    let url = "\(host)services/data/v54.0/sobjects/\(objectName)/\(id)"
    guard let updateUrl = URL(string: "\(url)")
    else {
      throw SSSDKError.invalidUrlError(url: host)
    }
    return updateUrl
  }

  ///  Creates URL for insertData api
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  ///     - objectName: Object name to insert record.
  /// - Throws: `SSSDKError.invalidUrlError` if the provided host url is invalid
  /// - Returns: returns URL for insertData api.
  public static func insertDataURL(config: SFConfig,
                                   objectName: String) throws -> URL {
    let host = verifyHost(host: config.host)
    let url = "\(host)services/data/v54.0/sobjects/\(objectName)"
    guard let insertUrl = URL(string: "\(url)")
    else {
      throw SSSDKError.invalidUrlError(url: host)
    }
    return insertUrl
  }

  ///  Creates URL for upsertData api
  /// - Parameters:
  ///     - config: The Salesforce instance’s configuration.
  ///     - objectName: Name of the object to upsert record into.
  ///     - externalIdFieldName: External field's name
  ///     - externalIdFieldValue: External field's value
  /// - Throws: `SSSDKError.invalidUrlError` if the provided host url is invalid
  /// - Returns: returns URL for upsertData api.
  public static func upsertDataURL(config: SFConfig,
                                   objectName: String,
                                   externalIdFieldName: String,
                                   externalIdFieldValue: String) throws -> URL {
    let host = verifyHost(host: config.host)
    let url = "\(host)services/data/v54.0/sobjects/\(objectName)/\(externalIdFieldName)/\(externalIdFieldValue)"
    guard let upsertUrl = URL(string: "\(url)")
    else {
      throw SSSDKError.invalidUrlError(url: host)
    }
    return upsertUrl
  }
}
