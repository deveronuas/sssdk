import XCTest
@testable import SimpleSalesforceSDK

class SSSDKTests: XCTestCase {

  /// When sssdk is configured
  func testShouldNotRunTimeThrowError () throws {
    let customRunTimeError = ConfigurationError
      .runtimeError("SSSDK not configured yet")
      .localizedDescription
    SSSDK.shared.configure(host: "https://www.google.com/?client=safari",
                           redirectUri: "appUrl://test",
                           clientId: "testclientid",
                           clientSecret: "testclientsecret")
    let url = try XCTUnwrap(URL(string: MockData().mockReceivedUrl))
    XCTAssertNotNil(url)
    SSSDK.shared.handleAuthRedirect(urlReceived: url)
    XCTAssertNoThrow(try SSSDK.shared.loginView(), customRunTimeError)
    XCTAssertNoThrow(try SSSDK.shared.refershAccessToken(), customRunTimeError)
  }

  /// When Access Token is not provided
  func testShouldThrowRunTimeError () throws {
    SSSDK.shared.configure(host: "https://www.google.com/?client=safari",
                           redirectUri: "appUrl://test",
                           clientId: "testclientid",
                           clientSecret: "testclientsecret")

    let customRunTimeError = ConfigurationError
      .runtimeError("Access Token missing")
      .localizedDescription

    XCTAssertThrowsError(
      try SSSDK.shared.fetchData(by: "", completionHandler: { data in
      })) { error in
        XCTAssertEqual(error.localizedDescription,customRunTimeError)
      }
  }

  func testHandleRedirect () throws {
    let url = try XCTUnwrap(URL(string: MockData().mockReceivedUrl))
    XCTAssertNotNil(url)
    SSSDK.shared.handleAuthRedirect(urlReceived: url)
  }
}
