//
//  HttpRawResponseHandlerTests.swift
//  VerificationTests
//

import XCTest
@testable import Verification

class HttpRawResponseHandlerTests: XCTestCase {

    func testExtractsResponseCodeAndLocation() {
        let raw = """
        HTTP/1.1 200 OK
        Content-Type: text/plain
        Location: https://example.com/verify/success

        SUCCESSFUL
        """
        let handler = HttpRawResponseHandler(raw)
        XCTAssertEqual(handler.responseCode, 200)
        XCTAssertEqual(handler.locationHeader, "https://example.com/verify/success")
    }

    func testMissingLocationReturnsNil() {
        let raw = "HTTP/1.0 400 Bad Request\n\nERROR"
        let handler = HttpRawResponseHandler(raw)
        XCTAssertEqual(handler.responseCode, 400)
        XCTAssertNil(handler.locationHeader)
    }

    func testMalformedStatusLineReturnsNilCode() {
        let raw = "NOSTATUS\nLocation: https://x.com\n"
        let handler = HttpRawResponseHandler(raw)
        XCTAssertNil(handler.responseCode)
        XCTAssertEqual(handler.locationHeader, "https://x.com")
    }

    func testFindsFirstIntegerTokenAsCode() {
        let raw = "Status 302 Found\nLocation: /next\n"
        let handler = HttpRawResponseHandler(raw)
        XCTAssertEqual(handler.responseCode, 302)
    }
}
