//
//  AutoVerificationMethodTests.swift
//  VerificationTests
//

import Mocker
import XCTest
@testable import Verification

class AutoVerificationMethodTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Auto initiation triggers seamless GET via Alamofire
        Mock(
            url: URL(string: "http://example.com")!,
            dataType: .json,
            statusCode: 200,
            data: [.get: VerificationResponseData.correctVerificationResponse(fromSource: .seamless, method: .seamless).asData!]
        ).register()
        Mock(
            url: URL(string: "http://example.com/seamless")!,
            dataType: .json,
            statusCode: 200,
            data: [.get: VerificationResponseData.correctVerificationResponse(fromSource: .seamless, method: .seamless).asData!]
        ).register()
    }

    func testCorrectAutoInitiationResponseNotifiesListener() throws {
        try createHelper().testCorrectInitiationResponseNotifiesInitListenerWithProperData()
    }

    func testErrorResponseNotifiesInitListenerWithApiError() throws {
        try createHelper().testErrorResponseNotifiesInitListenerWithApiError()
    }

    func testInitiationEmitsSeamlessSubMethodEvent() throws {
        let eventExpectation = expectation(description: "seamless sub-method event")
        let helper = EventCapturingHelper()
        helper.onEvent = { event in
            guard let autoEvent = event as? AutoVerificationEvent,
                  case .subMethodVerificationCallEvent(let method) = autoEvent,
                  method == .seamless else { return }
            eventExpectation.fulfill()
        }
        let method = AutoVerificationMethod(
            verificationMethodConfig: AutoVerificationConfig(
                globalConfig: SinchGlobalConfig.mockedManagerInstance(),
                number: "+48123456789"
            ),
            initiationListener: helper,
            verificationListener: helper
        )
        let response = initiationResponseWithSubIds(targetUri: "http://example.com/seamless")
        Mock(
            url: CommonVerificationMethodsTestsHelper.defaultTestInitURL,
            dataType: .json,
            statusCode: 200,
            data: [.post: response.asData!]
        ).register()

        method.initiate()
        waitForExpectations(timeout: 1.5)
    }

    func testVerifyByIdForSmsFlashcallAndCallout() throws {
        let helper = EventCapturingHelper()

        let method = AutoVerificationMethod(
            verificationMethodConfig: AutoVerificationConfig(
                globalConfig: SinchGlobalConfig.mockedManagerInstance(),
                number: "+48123456789"
            ),
            initiationListener: helper,
            verificationListener: helper
        )
        method.initiationResponseData = initiationResponseWithSubIds(targetUri: "http://example.com/seamless")

        // Call onVerify directly to exercise Auto paths without canVerify race between async callbacks
        registerVerifyByIdMock(id: "sms-sub-id", method: .sms)
        let smsExp = expectation(description: "sms verified")
        helper.verifiedHandler = { smsExp.fulfill() }
        method.onVerify("1111", fromSource: .manual, usingMethod: .sms)
        wait(for: [smsExp], timeout: 1.5)

        registerVerifyByIdMock(id: "fc-sub-id", method: .flashcall)
        let fcExp = expectation(description: "flashcall verified")
        helper.verifiedHandler = { fcExp.fulfill() }
        method.update(newState: .idle)
        method.onVerify("+48111", fromSource: .manual, usingMethod: .flashcall)
        wait(for: [fcExp], timeout: 1.5)

        registerVerifyByIdMock(id: "co-sub-id", method: .callout)
        let coExp = expectation(description: "callout verified")
        helper.verifiedHandler = { coExp.fulfill() }
        method.update(newState: .idle)
        method.onVerify("9999", fromSource: .manual, usingMethod: .callout)
        wait(for: [coExp], timeout: 1.5)

        XCTAssertTrue(helper.events.contains { event in
            guard let autoEvent = event as? AutoVerificationEvent,
                  case .subMethodVerificationCallEvent(let m) = autoEvent else { return false }
            return m == .sms
        })
    }

    func testVerifyReturnsEarlyWithoutMethodOrSubId() {
        let helper = EventCapturingHelper()
        let method = AutoVerificationMethod(
            verificationMethodConfig: AutoVerificationConfig(
                globalConfig: SinchGlobalConfig.mockedManagerInstance(),
                number: "+48123456789"
            ),
            initiationListener: helper,
            verificationListener: helper
        )
        // No initiation data → no subVerificationId
        method.update(newState: .idle)
        method.verify(verificationCode: "1234", method: .sms)
        XCTAssertFalse(helper.events.contains { event in
            guard let autoEvent = event as? AutoVerificationEvent,
                  case .subMethodVerificationCallEvent(let m) = autoEvent else { return false }
            return m == .sms
        })

        // Initiation without sms sub id
        let response = InitiationResponseData(
            id: "id",
            method: .auto,
            smsDetails: SmsInitiationDetails(subVerificationId: nil, template: "", interceptionTimeout: 60),
            flashcallDetails: nil,
            seamlessDetails: nil,
            calloutDetails: nil,
            contentLanguage: nil,
            dateOfGeneration: nil
        )
        method.onInitiated(response)
        method.update(newState: .idle)
        let eventsBefore = helper.events.count
        method.verify(verificationCode: "1234", method: .sms)
        XCTAssertEqual(helper.events.count, eventsBefore)
    }

    // MARK: - Helpers

    private func createHelper() -> CommonVerificationMethodsTestsHelper {
        let helper = CommonVerificationMethodsTestsHelper(testCase: self, verificationMethodType: .auto)
        let method = AutoVerificationMethod(
            verificationMethodConfig: AutoVerificationConfig(
                globalConfig: SinchGlobalConfig.mockedManagerInstance(),
                number: ""
            ),
            initiationListener: helper,
            verificationListener: helper
        )
        helper.method = method
        return helper
    }

    private func initiationResponseWithSubIds(targetUri: String) -> InitiationResponseData {
        return InitiationResponseData(
            id: "auto-id",
            method: .auto,
            smsDetails: SmsInitiationDetails(subVerificationId: "sms-sub-id", template: "", interceptionTimeout: 60),
            flashcallDetails: FlashcallInitiationDetails(subVerificationId: "fc-sub-id", interceptionTimeout: 60),
            seamlessDetails: SeamlessInitiationDetails(subVerificationId: "sm-sub-id", targetUri: targetUri),
            calloutDetails: CalloutInitiationDetails(subVerificationId: "co-sub-id"),
            contentLanguage: nil,
            dateOfGeneration: Date(timeIntervalSince1970: 0)
        )
    }

    private func registerVerifyByIdMock(id: String, method: VerificationMethodType) {
        let url = URL(string: "\(Constants.Api.domain)verification/\(Constants.Api.version)/verifications/id/\(id)")!
        Mock(
            url: url,
            dataType: .json,
            statusCode: 200,
            data: [.put: VerificationResponseData.correctVerificationResponse(fromSource: .manual, method: method).asData!]
        ).register()
    }
}

private final class EventCapturingHelper: InitiationListener, VerificationListener {
    var events: [VerificationEvent] = []
    var onEvent: ((VerificationEvent) -> Void)?
    var verifiedHandler: (() -> Void)?

    func onInitiated(_ data: InitiationResponseData) {}
    func onInitiationFailed(e: Error) {}
    func onVerified() { verifiedHandler?() }
    func onVerificationFailed(e: Error) {}
    func onVerificationEvent(event: VerificationEvent) {
        events.append(event)
        onEvent?(event)
    }
}
