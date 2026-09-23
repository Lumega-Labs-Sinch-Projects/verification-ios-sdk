//
//  VerificationMethodBuilderTests.swift
//  VerificationTests
//

import XCTest
@testable import Verification

class VerificationMethodBuilderTests: XCTestCase {

    private lazy var globalConfig = SinchGlobalConfig.mockedManagerInstance()
    private let number = "+48123456789"

    func testSmsMethodBuilder() {
        let config = SmsVerificationConfig(globalConfig: globalConfig, number: number)
        let method = SmsVerificationMethod.Builder.instance()
            .config(config)
            .build()
        XCTAssertTrue(method is SmsVerificationMethod)
    }

    func testFlashcallMethodBuilder() {
        let config = FlashcallVerificationConfig(globalConfig: globalConfig, number: number)
        let method = FlashcallVerificationMethod.Builder.instance()
            .config(config)
            .build()
        XCTAssertTrue(method is FlashcallVerificationMethod)
    }

    func testCalloutMethodBuilder() {
        let config = CalloutVerificationConfig(globalConfig: globalConfig, number: number)
        let method = CalloutVerificationMethod.Builder.instance()
            .config(config)
            .build()
        XCTAssertTrue(method is CalloutVerificationMethod)
    }

    func testSeamlessMethodBuilder() {
        let config = SeamlessVerificationConfig(globalConfig: globalConfig, number: number)
        let method = SeamlessVerificationMethod.Builder.instance()
            .config(config)
            .build()
        XCTAssertTrue(method is SeamlessVerificationMethod)
    }

    func testAutoMethodBuilder() {
        let config = AutoVerificationConfig(globalConfig: globalConfig, number: number)
        let method = AutoVerificationMethod.Builder.instance()
            .config(config)
            .build()
        XCTAssertTrue(method is AutoVerificationMethod)
    }
}
