//
//  VerificationDataTypesTests.swift
//  VerificationTests
//

import XCTest
@testable import Verification

class VerificationDataTypesTests: XCTestCase {

    func testSmsVerificationDataEncodes() throws {
        let data = SmsVerificationData(
            smsDetails: SmsVerificationDetails(code: "1111"),
            source: .manual
        )
        XCTAssertEqual(data.method, .sms)
        XCTAssertNotNil(data.asDictionary["sms"])
        XCTAssertNil(data.calloutDetails)
        XCTAssertNil(data.flashcallDetails)
    }

    func testFlashcallVerificationDataEncodes() throws {
        let data = FlashcallVerificationData(
            flashcallDetails: FlashcallVerificationDetails(cli: "+48000"),
            source: .interception
        )
        XCTAssertEqual(data.method, .flashcall)
        XCTAssertNotNil(data.asDictionary["flashcall"])
        XCTAssertNil(data.smsDetails)
    }

    func testCalloutVerificationDataEncodes() throws {
        let data = CalloutVerificationData(
            calloutDetails: CalloutVerificationDetails(code: "2222"),
            source: .manual
        )
        XCTAssertEqual(data.method, .callout)
        XCTAssertNotNil(data.asDictionary["callout"])
        XCTAssertNil(data.smsDetails)
    }
}
