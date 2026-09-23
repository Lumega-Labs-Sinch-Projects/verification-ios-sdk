//
//  FlashcallVerificationConfigTests.swift
//  VerificationTests
//

import XCTest
@testable import Verification

class FlashcallVerificationConfigTests: XCTestCase {

    let testGlobalConfig = SinchGlobalConfig.Builder.instance()
        .authorizationMethod(AppKeyAuthorizationMethod(appKey: "")).build()
    let testNumber = "+48123456789"
    let testCustom = "custom"
    let testReference = "reference"
    let honoursEarly = false
    let acceptedLanguages = [try! VerificationLanguage(language: "pl")]

    func testBasicBuilder() throws {
        let builtConfiguration = FlashcallVerificationConfig.Builder.instance()
            .globalConfig(testGlobalConfig)
            .number(testNumber)
            .build()

        let initializedConfig = FlashcallVerificationConfig(globalConfig: testGlobalConfig, number: testNumber)
        XCTAssertTrue(builtConfiguration.commonPropertiesMatch(initializedConfig))
    }

    func testFullBuilder() throws {
        let builtConfiguration = FlashcallVerificationConfig.Builder.instance()
            .globalConfig(testGlobalConfig)
            .number(testNumber)
            .acceptedLanguages(acceptedLanguages)
            .custom(testCustom)
            .honourEarlyReject(honoursEarly)
            .reference(testReference)
            .build()

        let initializedConfig = FlashcallVerificationConfig(
            globalConfig: testGlobalConfig,
            number: testNumber,
            custom: testCustom,
            reference: testReference,
            honoursEarlyReject: honoursEarly,
            acceptedLanguages: acceptedLanguages
        )
        XCTAssertTrue(builtConfiguration.commonPropertiesMatch(initializedConfig))
    }

    func testFullBuilderParametersExpectations() {
        let builtConfiguration = FlashcallVerificationConfig.Builder.instance()
            .globalConfig(testGlobalConfig)
            .number(testNumber)
            .acceptedLanguages(acceptedLanguages)
            .custom(testCustom)
            .honourEarlyReject(honoursEarly)
            .reference(testReference)
            .build()

        XCTAssertEqual(builtConfiguration.number, testNumber)
        XCTAssertEqual(builtConfiguration.acceptedLanguages, acceptedLanguages)
        XCTAssertEqual(builtConfiguration.custom, testCustom)
        XCTAssertEqual(builtConfiguration.reference, testReference)
        XCTAssertEqual(builtConfiguration.honoursEarlyReject, honoursEarly)
    }

    func testDefaultParametersExpected() {
        let builtConfiguration = FlashcallVerificationConfig.Builder.instance()
            .globalConfig(testGlobalConfig)
            .number(testNumber)
            .build()

        XCTAssertEqual(builtConfiguration.number, testNumber)
        XCTAssertEqual(builtConfiguration.acceptedLanguages, [])
        XCTAssertNil(builtConfiguration.custom)
        XCTAssertNil(builtConfiguration.reference)
        XCTAssertEqual(builtConfiguration.honoursEarlyReject, true)
    }

    func testWithVerificationProperties() {
        let props = VerificationInitData(
            usedMethod: .flashcall,
            number: testNumber,
            custom: testCustom,
            reference: testReference,
            honoursEarlyReject: honoursEarly,
            acceptedLanguages: acceptedLanguages
        )
        let built = FlashcallVerificationConfig.Builder.instance()
            .globalConfig(testGlobalConfig)
            .withVerificationProperties(props)
            .build()

        XCTAssertTrue(built.commonPropertiesMatch(props))
    }
}
