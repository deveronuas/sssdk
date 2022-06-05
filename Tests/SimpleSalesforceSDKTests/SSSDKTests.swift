import XCTest
@testable import SimpleSalesforceSDK

class SSSDKTests: XCTestCase {

//  /// When sssdk is configured
//  func testShouldNotRunTimeThrowError () throws {
//    let customRunTimeError = SSSDKError.invalidConfigurationError.localizedDescription
//    
//    SSSDK.shared.configure(host: "https://www.google.com/?client=safari",
//                           redirectUri: "appUrl://test",
//                           clientId: "testclientid",
//                           clientSecret: "testclientsecret")
//    let url = try XCTUnwrap(URL(string: MockData().mockReceivedUrl))
//    XCTAssertNotNil(url)
//    try! SSSDK.shared.handleAuthRedirect(urlReceived: url) { _ in }
//    XCTAssertNoThrow(try SSSDK.shared.loginView(), customRunTimeError)
//    XCTAssertNoThrow(try SSSDK.shared.refershAccessToken() { error in
//      XCTAssertNotNil(error)
//    }, customRunTimeError)
//  }
//
//  /// When Access Token is not provided
//  func testShouldThrowRunTimeError () throws {
//    SSSDK.shared.configure(host: "https://www.google.com/?client=safari",
//                           redirectUri: "appUrl://test",
//                           clientId: "testclientid",
//                           clientSecret: "testclientsecret")
//
//    let customRunTimeError = SSSDKError.invalidConfigurationError.localizedDescription
//
//    XCTAssertThrowsError(
//      try SSSDK.shared.fetchData(by: "", completionHandler: { data, error in
//      })) { error in
//        XCTAssertEqual(error.localizedDescription,customRunTimeError)
//      }
//  }
//
//  func testHandleRedirect () throws {
//    let url = try XCTUnwrap(URL(string: MockData().mockReceivedUrl))
//    XCTAssertNotNil(url)
//    try! SSSDK.shared.handleAuthRedirect(urlReceived: url) { _ in }
//  }
}
