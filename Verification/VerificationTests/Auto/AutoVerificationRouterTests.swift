//
//  AutoVerificationRouterTests.swift
//  VerificationTests
//

import Alamofire
import XCTest
@testable import Verification

class AutoVerificationRouterTests: XCTestCase {

    func testInitiateVerificationRequestShape() throws {
        let language = try VerificationLanguage(language: "en")
        let data = AutoVerificationInitiationData(
            identity: VerificationIdentity(endpoint: "+48123456789"),
            honourEarlyReject: true,
            custom: "custom",
            reference: "ref",
            metadata: nil
        )
        let router = AutoVerificationRouter.initiateVerification(data: data, preferedLanguages: [language])
        let request = try router.asURLRequest()

        XCTAssertEqual(router.method, .post)
        XCTAssertEqual(router.path, "verifications")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertTrue(request.url?.absoluteString.contains("verifications") ?? false)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Language"), language.httpHeader)
        XCTAssertNotNil(request.httpBody)
    }

    func testInitiateVerificationEmptyLanguageHeader() throws {
        let data = AutoVerificationInitiationData(
            identity: VerificationIdentity(endpoint: "+48123456789"),
            honourEarlyReject: false,
            custom: nil,
            reference: nil,
            metadata: nil
        )
        let request = try AutoVerificationRouter.initiateVerification(data: data, preferedLanguages: []).asURLRequest()
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Language"), "")
    }
}
