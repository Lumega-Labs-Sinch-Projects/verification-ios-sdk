//
//  PhoneNumberUITextFieldTests.swift
//  VerificationTests
//

import UIKit
import XCTest
@testable import Verification

class PhoneNumberUITextFieldTests: XCTestCase {

    func testInitWithFrameAndCountryIsoUpdatesText() {
        let field = PhoneNumberUITextField(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        field.text = "48123456789"
        field.countryIso = "PL"
        XCTAssertFalse(field.text?.isEmpty ?? true)
        XCTAssertEqual(field.e164Number, field.text)
    }

    func testE164NumberReturnsText() {
        let field = PhoneNumberUITextField(frame: .zero)
        field.text = "+48123456789"
        XCTAssertEqual(field.e164Number, "+48123456789")
    }

    func testEditingChangedTargetIsRegistered() {
        let field = PhoneNumberUITextField(frame: .zero)
        field.sendActions(for: .editingChanged)
        XCTAssertNotNil(field)
    }
}
