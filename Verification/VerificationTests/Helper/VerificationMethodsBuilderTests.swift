//
//  VerificationMethodsBuilderTests.swift
//  VerificationTests
//

import XCTest
@testable import Verification

class VerificationMethodsBuilderTests: XCTestCase {

    private let globalConfig = SinchGlobalConfig.Builder.instance()
        .authorizationMethod(AppKeyAuthorizationMethod(appKey: "key"))
        .build()
    private let number = "+48123456789"

    func testCreatesSmsVerification() {
        let verification = createVerification(for: .sms)
        XCTAssertTrue(verification is SmsVerificationMethod)
    }

    func testCreatesFlashcallVerification() {
        let verification = createVerification(for: .flashcall)
        XCTAssertTrue(verification is FlashcallVerificationMethod)
    }

    func testCreatesCalloutVerification() {
        let verification = createVerification(for: .callout)
        XCTAssertTrue(verification is CalloutVerificationMethod)
    }

    func testCreatesSeamlessVerification() {
        let verification = createVerification(for: .seamless)
        XCTAssertTrue(verification is SeamlessVerificationMethod)
    }

    func testCreatesAutoVerification() {
        let verification = createVerification(for: .auto)
        XCTAssertTrue(verification is AutoVerificationMethod)
    }

    func testVerificationMethodTypeAllowsManualVerificationFlags() {
        XCTAssertTrue(VerificationMethodType.sms.allowsManualVerification)
        XCTAssertTrue(VerificationMethodType.flashcall.allowsManualVerification)
        XCTAssertTrue(VerificationMethodType.callout.allowsManualVerification)
        XCTAssertTrue(VerificationMethodType.auto.allowsManualVerification)
        XCTAssertFalse(VerificationMethodType.seamless.allowsManualVerification)
    }

    private func createVerification(for method: VerificationMethodType) -> Verification {
        let initData = VerificationInitData(
            usedMethod: method,
            number: number,
            custom: "custom",
            reference: "ref",
            honoursEarlyReject: true,
            acceptedLanguages: []
        )
        let parameters = CommonVerificationInitializationParameters(
            globalConfig: globalConfig,
            verificationInitData: initData
        )
        return VerificationMethodsBuilder.createVerification(withParameters: parameters)
    }
}
