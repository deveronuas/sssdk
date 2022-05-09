import XCTest
@testable import SimpleSalesforceSDK

class APIResponseTests: XCTestCase {

  let decoder = JSONDecoder()

  func testDecodeRefreshTokenResponse () throws {
    let mockResponse = try XCTUnwrap(MockData()
      .refreshTokenResponseData.data(using: .utf8))

    let data = try XCTUnwrap(decoder.decode(RefreshTokenResponse.self,
                                                   from: mockResponse))

    XCTAssertNotNil(data)
  }
  
  func testDecodeIntrospectResponse () throws {
    let mockResponse = try XCTUnwrap(MockData()
      .introspectApiResponseData.data(using: .utf8))

    let data = try XCTUnwrap(decoder.decode(IntrospectResponse.self,
                                            from: mockResponse))
    
    XCTAssertNotNil(data)
  }
}
