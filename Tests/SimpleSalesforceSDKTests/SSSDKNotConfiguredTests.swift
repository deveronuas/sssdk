import XCTest
@testable import SimpleSalesforceSDK

// When SSSDK is not configured
class SSSDKNotConfiguredTests: XCTestCase {

  let customRunTimeError = SSSDKError.invalidConfigurationError.localizedDescription
  
  func testShouldThrowRuntimeError () throws {
    XCTAssertThrowsError(try SSSDK.shared.refershAccessToken(){ error in
      XCTAssertNotNil(error)
    }) { error in
      XCTAssertEqual(error.localizedDescription, customRunTimeError)
      return
    }

    XCTAssertThrowsError(try SSSDK.shared.loginView()) { error in
      XCTAssertEqual(error.localizedDescription, customRunTimeError)
      return
    }
    
    XCTAssertThrowsError(try SSSDK.shared.fetchData(by: "", completionHandler: { data, error in
    })) { error in
      XCTAssertEqual(error.localizedDescription, customRunTimeError)
      return 
    }
  }
}
