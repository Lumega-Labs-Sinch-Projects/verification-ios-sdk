//
//  SeamlessVerificationConfigTests.swift
//  VerificationTests
//

import XCTest
@testable import Verification

class SeamlessVerificationConfigTests: XCTestCase {

    let testGlobalConfig = SinchGlobalConfig.Builder.instance()
        .authorizationMethod(AppKeyAuthorizationMethod(appKey: "")).build()
    let testNumber = "+48123456789"
    let testCustom = "custom"
    let testReference = "reference"
    let honoursEarly = false
    let acceptedLanguages = [try! VerificationLanguage(language: "pl")]

    func testBasicBuilder() throws {
        let builtConfiguration = SeamlessVerificationConfig.Builder.instance()
            .globalConfig(testGlobalConfig)
            .number(testNumber)
            .build()

        let initializedConfig = SeamlessVerificationConfig(globalConfig: testGlobalConfig, number: testNumber)
        XCTAssertTrue(builtConfiguration.commonPropertiesMatch(initializedConfig))
    }

    func testFullBuilder() throws {
        let builtConfiguration = SeamlessVerificationConfig.Builder.instance()
            .globalConfig(testGlobalConfig)
            .number(testNumber)
            .acceptedLanguages(acceptedLanguages)
            .custom(testCustom)
            .honourEarlyReject(honoursEarly)
            .reference(testReference)
            .build()

        let initializedConfig = SeamlessVerificationConfig(
            globalConfig: testGlobalConfig,
            number: testNumber,
            custom: testCustom,
            reference: testReference,
            honoursEarlyReject: honoursEarly,
            acceptedLanguages: acceptedLanguages
        )
        XCTAssertTrue(builtConfiguration.commonPropertiesMatch(initializedConfig))
    }

    func testSkipLocalInitializationAllowsNilNumber() {
        let built = SeamlessVerificationConfig.Builder.instance()
            .globalConfig(testGlobalConfig)
            .skipLocalInitialization()
            .custom(testCustom)
            .build()

        XCTAssertNil(built.number)
        XCTAssertEqual(built.custom, testCustom)
    }

    func testWithVerificationPropertiesUsesNumber() {
        let props = VerificationInitData(
            usedMethod: .seamless,
            number: testNumber,
            custom: testCustom,
            reference: testReference,
            honoursEarlyReject: honoursEarly,
            acceptedLanguages: acceptedLanguages
        )
        let built = SeamlessVerificationConfig.Builder.instance()
            .globalConfig(testGlobalConfig)
            .withVerificationProperties(props)
            .build()

        XCTAssertTrue(built.commonPropertiesMatch(props))
    }

    func testWithVerificationPropertiesSkipWhenNumberNil() {
        // VerificationInitData requires a String number; use a temporary properties shim via empty number path
        // by calling skipLocalInitialization path through a custom struct.
        struct NilNumberProps: VerificationMethodProperties {
            let number: String? = nil
            let custom: String? = "c"
            let reference: String? = "r"
            let honoursEarlyReject: Bool = false
            let acceptedLanguages: [VerificationLanguage] = []
        }
        let built = SeamlessVerificationConfig.Builder.instance()
            .globalConfig(testGlobalConfig)
            .withVerificationProperties(NilNumberProps())
            .build()

        XCTAssertNil(built.number)
        XCTAssertEqual(built.custom, "c")
        XCTAssertEqual(built.reference, "r")
        XCTAssertEqual(built.honoursEarlyReject, false)
    }

    func testDefaultParametersExpected() {
        let builtConfiguration = SeamlessVerificationConfig.Builder.instance()
            .globalConfig(testGlobalConfig)
            .number(testNumber)
            .build()

        XCTAssertEqual(builtConfiguration.number, testNumber)
        XCTAssertEqual(builtConfiguration.acceptedLanguages, [])
        XCTAssertNil(builtConfiguration.custom)
        XCTAssertNil(builtConfiguration.reference)
        XCTAssertEqual(builtConfiguration.honoursEarlyReject, true)
    }
}
