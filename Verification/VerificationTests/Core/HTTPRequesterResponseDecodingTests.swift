//
//  HTTPRequesterResponseDecodingTests.swift
//  VerificationTests
//
//  Copyright © 2026 Sinch. All rights reserved.
//

import XCTest
@testable import Verification

/// Replicates / guards the seamless Release buffer-length bug in `HTTPRequester`.
///
/// Pre-fix code decoded `sizeof(buffer)` (capacity) instead of bytes received. Unread
/// stack memory then either:
/// 1) made `NSASCIIStringEncoding` return nil → `Error when executing HTTP requests`, or
/// 2) polluted the decoded string with garbage after the real HTTP body.
///
/// The fix decodes only `responseLength` (bytes actually read).
final class HTTPRequesterResponseDecodingTests: XCTestCase {

    private let bufferCapacity = 4096
    private let httpResponse = "HTTP/1.1 200 OK\r\nContent-Length: 10\r\n\r\nSUCCESSFUL"

    /// 4096-byte buffer: valid HTTP in the prefix, 0xFF in the unread region
    /// (Release stack garbage shape after a short cellular read).
    private func poisonedHTTPBuffer() -> (buffer: [UInt8], received: Int) {
        var buffer = [UInt8](repeating: 0, count: bufferCapacity)
        let received = Array(httpResponse.utf8)
        precondition(received.count < bufferCapacity)
        buffer.replaceSubrange(0..<received.count, with: received)
        for i in received.count..<bufferCapacity {
            buffer[i] = 0xFF
        }
        return (buffer, received.count)
    }

    func testPreFixCapacityLengthEitherFailsASCIIOrIncludesUnreadGarbage() {
        let (buffer, received) = poisonedHTTPBuffer()

        let preFixDecode = buffer.withUnsafeBytes { raw -> String? in
            guard let base = raw.baseAddress else { return nil }
            // Pre-fix: length was buffer capacity, not bytes received.
            return HTTPRequester.asciiString(fromResponseBuffer: base, length: UInt(buffer.count)) as String?
        }

        if let preFixDecode {
            // Some Foundation versions lossily accept 0xFF (shown as ÿ) instead of returning nil.
            XCTAssertGreaterThan(
                preFixDecode.utf8.count,
                received,
                "Capacity-sized decode must include unread buffer bytes"
            )
            XCTAssertTrue(
                preFixDecode.contains("\u{00FF}") || preFixDecode.contains("ÿ"),
                "Capacity-sized decode must retain unread 0xFF garbage"
            )
        } else {
            // Strict ASCII path: nil → seamless surfaces Error when executing HTTP requests.
            XCTAssertNil(preFixDecode)
        }
    }

    func testFixedDecodeUsesOnlyReceivedBytesAndIgnoresUnreadGarbage() {
        let (buffer, received) = poisonedHTTPBuffer()

        let fixed = buffer.withUnsafeBytes { raw -> String? in
            guard let base = raw.baseAddress else { return nil }
            return HTTPRequester.string(fromResponseBuffer: base, length: UInt(received)) as String?
        }

        XCTAssertEqual(fixed, httpResponse)
        XCTAssertFalse(fixed?.contains("\u{00FF}") == true)
        XCTAssertFalse(fixed?.contains("ÿ") == true)
        XCTAssertTrue(fixed?.contains("SUCCESSFUL") == true)
    }

    func testAsciiDecodeAlsoSucceedsWhenLengthMatchesReceivedBytes() {
        let (buffer, received) = poisonedHTTPBuffer()

        let asciiOnly = buffer.withUnsafeBytes { raw -> String? in
            guard let base = raw.baseAddress else { return nil }
            return HTTPRequester.asciiString(fromResponseBuffer: base, length: UInt(received)) as String?
        }

        XCTAssertEqual(asciiOnly, httpResponse)
    }

    func testStringFromResponseBufferRejectsEmptyLength() {
        let buffer: [UInt8] = [0x48] // 'H'
        let result = buffer.withUnsafeBytes { raw -> String? in
            guard let base = raw.baseAddress else { return nil }
            return HTTPRequester.string(fromResponseBuffer: base, length: 0) as String?
        }
        XCTAssertNil(result)
    }

    func testStringFromResponseBufferFallsBackForNonASCIIBodyBytes() {
        var bytes = Array("HTTP/1.1 200 OK\r\n\r\n".utf8)
        bytes.append(0xA9) // ©

        let result = bytes.withUnsafeBytes { raw -> String? in
            guard let base = raw.baseAddress else { return nil }
            return HTTPRequester.string(fromResponseBuffer: base, length: UInt(bytes.count)) as String?
        }

        XCTAssertNotNil(result, "Latin-1 fallback should keep non-ASCII bodies decodable")
        XCTAssertTrue(result?.hasPrefix("HTTP/1.1") == true)
    }
}
