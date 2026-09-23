//
//  ExtensionAndModelCoverageTests.swift
//  VerificationTests
//

import XCTest
@testable import Verification

class ExtensionAndModelCoverageTests: XCTestCase {

    func testStringNilIfEmptyAndPrefixed() {
        XCTAssertNil("".nilIfEmpty())
        XCTAssertEqual("a".nilIfEmpty(), "a")
        XCTAssertEqual("x".prefixed(with: "pre"), "prex")
    }

    func testVerificationResponseDataAsSDKError() {
        let ok = VerificationResponseData(
            id: "1", source: .manual, status: .successful, method: .sms, errorReason: nil, reference: nil
        )
        XCTAssertNil(ok.asSDKError)

        let failed = VerificationResponseData(
            id: "1", source: .manual, status: .failed, method: .sms, errorReason: "bad", reference: "r"
        )
        guard let err = failed.asSDKError, case SDKError.apiCall(let data) = err else {
            return XCTFail("Expected apiCall error")
        }
        XCTAssertEqual(data.message, "bad")
        XCTAssertEqual(data.reference, "r")
    }

    func testDecodableMakeAndMakeSafe() throws {
        struct Sample: Codable, Equatable {
            let value: String
        }
        let json: JSON = ["value": "hello"]
        let fromJson = try Sample.make(from: json)
        XCTAssertEqual(fromJson, Sample(value: "hello"))

        let data = try JSONSerialization.data(withJSONObject: json)
        let fromData = try Sample.make(from: data)
        XCTAssertEqual(fromData.value, "hello")
        XCTAssertNil(Sample.makeSafe(from: Data("not-json".utf8)))
    }

    func testEncodableAsDictionaryPaths() throws {
        struct Sample: Encodable {
            let helloWorld: String
        }
        let sample = Sample(helloWorld: "x")
        XCTAssertEqual(sample.asDictionary["helloWorld"] as? String, "x")
        XCTAssertNotNil(sample.asData)

        // Force encoding failure path via a type that encodes to a non-object JSON value
        struct BareString: Encodable {
            func encode(to encoder: Encoder) throws {
                var c = encoder.singleValueContainer()
                try c.encode("just-a-string")
            }
        }
        XCTAssertTrue(BareString().asDictionary.isEmpty)
        XCTAssertNil(BareString().asData)
        XCTAssertThrowsError(try BareString().asDictionaryThrowable())

        _ = JSONEncoder.standard
    }

    func testProtocolDefaultImplementations() {
        final class EmptyInitListener: InitiationListener {}
        final class EmptyVerifyListener: VerificationListener {}
        let initListener = EmptyInitListener()
        let verifyListener = EmptyVerifyListener()
        let data = InitiationResponseData(
            id: "id", method: .sms, smsDetails: nil, flashcallDetails: nil,
            seamlessDetails: nil, calloutDetails: nil, contentLanguage: nil, dateOfGeneration: nil
        )
        initListener.onInitiated(data)
        initListener.onInitiationFailed(e: SDKError.unexpected(message: "x"))
        verifyListener.onVerified()
        verifyListener.onVerificationFailed(e: SDKError.unexpected(message: "y"))
        verifyListener.onVerificationEvent(event: AutoVerificationEvent.subMethodVerificationCallEvent(method: .sms))
    }

    func testHTTPRequesterErrorPathsOnSimulator() {
        // Simulator has no cellular interface → early ERROR_RESULT (covers ObjC branch).
        let result = HTTPRequester.performGetRequest(URL(string: "http://example.com")!)
        XCTAssertEqual(result, "ERROR")

        let withHeaders = HTTPRequester.performGetRequest(
            URL(string: "https://example.com/path?q=1")!,
            headers: ["X-Test": "1", "Empty": ""]
        )
        XCTAssertEqual(withHeaders, "ERROR")
    }
}
