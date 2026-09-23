//
//  NetworkingLogicCoverageTests.swift
//  VerificationTests
//

import Darwin
import XCTest
@testable import Verification

class NetworkingLogicCoverageTests: XCTestCase {

    func testSocketAddressIPv4SizeAndDescription() {
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr)

        let socketAddress = withUnsafePointer(to: &addr) { ptr -> SocketAddress in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                SocketAddress(sockaddr: UnsafeMutablePointer(mutating: sa))
            }
        }
        XCTAssertEqual(socketAddress.size, socklen_t(MemoryLayout<sockaddr_in>.size))
        let description = socketAddress.description ?? ""
        XCTAssertTrue(description.contains("IPv4"))
        XCTAssertTrue(description.contains("127.0.0.1"))
    }

    func testSocketAddressIPv6SizeAndDescription() {
        var addr = sockaddr_in6()
        addr.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
        addr.sin6_family = sa_family_t(AF_INET6)
        inet_pton(AF_INET6, "::1", &addr.sin6_addr)

        let socketAddress = withUnsafePointer(to: &addr) { ptr -> SocketAddress in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                SocketAddress(sockaddr: UnsafeMutablePointer(mutating: sa))
            }
        }
        XCTAssertEqual(socketAddress.size, socklen_t(MemoryLayout<sockaddr_in6>.size))
        let description = socketAddress.description ?? ""
        XCTAssertTrue(description.contains("IPv6"))
    }

    func testSocketAddressUnknownFamilyReturnsZeroSize() {
        var addr = sockaddr()
        addr.sa_family = sa_family_t(AF_UNSPEC)
        let socketAddress = withUnsafePointer(to: &addr) { ptr -> SocketAddress in
            SocketAddress(sockaddr: UnsafeMutablePointer(mutating: ptr))
        }
        XCTAssertEqual(socketAddress.size, 0)
    }

    func testSslReadAndWriteFullAndPartial() {
        var fds: [Int32] = [0, 0]
        XCTAssertEqual(pipe(&fds), 0)
        defer {
            close(fds[0])
            close(fds[1])
        }

        let payload = Array("hello-ssl".utf8)
        payload.withUnsafeBytes { raw in
            var length = payload.count
            var writeFd = fds[1]
            let status = withUnsafePointer(to: &writeFd) { conn in
                ssl_write(conn, raw.baseAddress, &length)
            }
            XCTAssertEqual(status, noErr)
            XCTAssertEqual(length, payload.count)
        }

        var buffer = [UInt8](repeating: 0, count: 64)
        buffer.withUnsafeMutableBytes { raw in
            var length = 64
            var readFd = fds[0]
            let status = withUnsafePointer(to: &readFd) { conn in
                ssl_read(conn, raw.baseAddress, &length)
            }
            // Requested 64 but only ~9 available → WouldBlock branch
            XCTAssertEqual(status, errSSLWouldBlock)
            XCTAssertEqual(length, payload.count)
        }

        // Full read matching available size
        var fds2: [Int32] = [0, 0]
        XCTAssertEqual(pipe(&fds2), 0)
        defer {
            close(fds2[0])
            close(fds2[1])
        }
        let two = Array("ab".utf8)
        two.withUnsafeBytes { raw in
            var length = two.count
            var writeFd = fds2[1]
            _ = withUnsafePointer(to: &writeFd) { ssl_write($0, raw.baseAddress, &length) }
        }
        var buf2 = [UInt8](repeating: 0, count: 2)
        buf2.withUnsafeMutableBytes { raw in
            var length = 2
            var readFd = fds2[0]
            let status = withUnsafePointer(to: &readFd) { ssl_read($0, raw.baseAddress, &length) }
            XCTAssertEqual(status, noErr)
            XCTAssertEqual(length, 2)
        }
    }
}
