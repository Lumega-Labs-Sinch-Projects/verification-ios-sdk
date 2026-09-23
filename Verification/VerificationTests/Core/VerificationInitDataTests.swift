//
//  VerificationInitDataTests.swift
//  VerificationTests
//

import XCTest
@testable import Verification

class VerificationInitDataTests: XCTestCase {

    func testStoresAllFields() throws {
        let languages = [try VerificationLanguage(language: "pl")]
        let data = VerificationInitData(
            usedMethod: .sms,
            number: "+48123456789",
            custom: "c",
            reference: "r",
            honoursEarlyReject: false,
            acceptedLanguages: languages
        )
        XCTAssertEqual(data.usedMethod, .sms)
        XCTAssertEqual(data.number, "+48123456789")
        XCTAssertEqual(data.custom, "c")
        XCTAssertEqual(data.reference, "r")
        XCTAssertEqual(data.honoursEarlyReject, false)
        XCTAssertEqual(data.acceptedLanguages, languages)
    }
}
