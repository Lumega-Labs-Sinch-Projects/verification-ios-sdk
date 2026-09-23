//
//  VerificationRouterTests.swift
//  VerificationTests
//

import XCTest
@testable import Verification

class VerificationRouterTests: XCTestCase {

    func testVerifyByIdRequestShape() throws {
        let data = SmsVerificationData(
            smsDetails: SmsVerificationDetails(code: "1234"),
            source: .manual
        )
        let router = VerificationRouter.verifyById(id: "sub-id-1", data: data)
        let request = try router.asURLRequest()

        XCTAssertEqual(router.method, .put)
        XCTAssertEqual(router.path, "verifications/id/sub-id-1")
        XCTAssertEqual(request.httpMethod, "PUT")
        XCTAssertTrue(request.url?.path.contains("verifications/id/sub-id-1") ?? false)
        XCTAssertNotNil(request.httpBody)
        XCTAssertEqual(router.headers.count, 0)
    }

    func testVerifyByIdWithFlashcallData() throws {
        let data = FlashcallVerificationData(
            flashcallDetails: FlashcallVerificationDetails(cli: "+48111"),
            source: .interception
        )
        let request = try VerificationRouter.verifyById(id: "fc-id", data: data).asURLRequest()
        XCTAssertEqual(request.httpMethod, "PUT")
        XCTAssertTrue(request.url?.absoluteString.contains("verifications/id/fc-id") ?? false)
    }

    func testVerifyByIdWithCalloutData() throws {
        let data = CalloutVerificationData(
            calloutDetails: CalloutVerificationDetails(code: "9999"),
            source: .manual
        )
        let request = try VerificationRouter.verifyById(id: "co-id", data: data).asURLRequest()
        XCTAssertNotNil(request.httpBody)
    }
}
