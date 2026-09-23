//
//  ApiErrorDataTests.swift
//  VerificationTests
//

import XCTest
@testable import Verification

class ApiErrorDataTests: XCTestCase {

    func testMightBePhoneFormattingErrorForParameterValidation() {
        let data = ApiErrorData(errorCode: 40001, message: "invalid", reference: nil)
        XCTAssertTrue(data.mightBePhoneFormattingError)
    }

    func testMightBePhoneFormattingErrorForMissingPlus() {
        let data = ApiErrorData(errorCode: 40005, message: "plus", reference: "r")
        XCTAssertTrue(data.mightBePhoneFormattingError)
    }

    func testMightBePhoneFormattingErrorFalseForOtherCodes() {
        let data = ApiErrorData(errorCode: 50000, message: "oops", reference: nil)
        XCTAssertFalse(data.mightBePhoneFormattingError)
    }

    func testMightBePhoneFormattingErrorFalseWhenNil() {
        let data = ApiErrorData(errorCode: nil, message: nil, reference: nil)
        XCTAssertFalse(data.mightBePhoneFormattingError)
    }
}
