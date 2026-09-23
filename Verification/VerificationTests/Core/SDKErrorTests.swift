//
//  SDKErrorTests.swift
//  VerificationTests
//

import XCTest
@testable import Verification

class SDKErrorTests: XCTestCase {

    func testIllegalArgumentDescription() {
        XCTAssertEqual(SDKError.illegalArgument(message: "bad arg").errorDescription, "bad arg")
    }

    func testEncodingDescription() {
        let description = SDKError.encoding(encodable: "value").errorDescription
        XCTAssertTrue(description?.contains("Encoding of") ?? false)
    }

    func testApiCallUsesMessage() {
        let data = ApiErrorData(errorCode: 1, message: "server said no", reference: nil)
        XCTAssertEqual(SDKError.apiCall(data: data).errorDescription, "server said no")
    }

    func testApiCallFallbackMessage() {
        let data = ApiErrorData(errorCode: 1, message: nil, reference: nil)
        XCTAssertEqual(
            SDKError.apiCall(data: data).errorDescription,
            "Sinch api returned an error without message"
        )
    }

    func testTimeoutAndUnexpectedDescriptions() {
        XCTAssertEqual(
            SDKError.timeoutException.errorDescription,
            "Verification process has not been completed within interception timeout"
        )
        XCTAssertEqual(SDKError.unexpected(message: "boom").errorDescription, "boom")
    }
}
