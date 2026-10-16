//
//  SeamlessVerificationMethodTests.swift
//  VerificationTests
//
//  Created by Aleksander Wojcik on 14/08/2020.
//  Copyright © 2020 Sinch. All rights reserved.
//

import Mocker
import XCTest
@testable import Verification

class SeamlessVerificationMethodTests: XCTestCase {

    private var previousCellularAvailabilityCheck: (() -> Bool)!

    override func setUp() {
        super.setUp()
        previousCellularAvailabilityCheck = SeamlessVerificationMethod.isCellularNetworkAvailable
        // Existing initiation tests mock HTTP only; stub cellular so simulator/CI without pdp_ip0 still run.
        SeamlessVerificationMethod.isCellularNetworkAvailable = { true }
    }

    override func tearDown() {
        SeamlessVerificationMethod.isCellularNetworkAvailable = previousCellularAvailabilityCheck
        super.tearDown()
    }
    
    func testCorrectSeamlessInitiationResponseNotifiesListener() throws {
        try createHelperWithSeamlessMethod().testCorrectInitiationResponseNotifiesInitListenerWithProperData()
    }

    func testPreInitiateFailsWhenCellularNetworkUnavailable() {
        SeamlessVerificationMethod.isCellularNetworkAvailable = { false }

        let expectation = expectation(description: "onInitiationFailed with cellular unavailable")
        let helper = createHelperWithSeamlessMethod()
        helper.onInitiatedFailedCallback = { error in
            XCTAssertEqual(
                error.localizedDescription,
                SeamlessVerificationMethod.cellularNetworkNotAvailableMessage
            )
            expectation.fulfill()
        }

        helper.method?.initiate()

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(helper.method?.verificationState, .idle)
    }
    
    func testErrorResponseNotifiesInitListenerWithApiError() throws {
        try createHelperWithSeamlessMethod().testErrorResponseNotifiesInitListenerWithApiError()
    }
    
    func testCorrentInitiationAutomaticallyCallsVerify() throws {
        let extraVerifyExpectationCalled = expectation(description: "onVerifyCalled after initiating successfully")
        let helper = createHelperWithSeamlessMethod()
        helper.onVerifiedCallback = {
            extraVerifyExpectationCalled.fulfill()
        }
        helper.mockCorrectVerification()
        try helper.testCorrectInitiationResponseNotifiesInitListenerWithProperData()
    }
    
    private func createMethod(withHelperAsListener helper: CommonVerificationMethodsTestsHelper) -> SeamlessVerificationMethod {
        return SeamlessVerificationMethod(
            verificationMethodConfig: SeamlessVerificationConfig(globalConfig: SinchGlobalConfig.mockedManagerInstance(), number: ""),
            initiationListener: helper,
            verificationListener: helper
        )
    }
    
    private func createHelperWithSeamlessMethod() -> CommonVerificationMethodsTestsHelper {
        let helper = CommonVerificationMethodsTestsHelper(testCase: self, verificationMethodType: .seamless, verificationUrlCreator: { data in
            return URL(string: data.seamlessDetails!.targetUri)!
        })
        let method = createMethod(withHelperAsListener: helper)
        helper.method = method
        return helper
    }
    
    func testIndianNumberRoutesToIndiaBaseUrl() throws {
        let previousIndiaDomain = Constants.Api.userDefinedIndiaDomain
        let previousDomain = Constants.Api.userDefinedDomain
        defer {
            Constants.Api.userDefinedIndiaDomain = previousIndiaDomain
            Constants.Api.userDefinedDomain = previousDomain
        }
        
        Constants.Api.userDefinedIndiaDomain = "https://india.test.sinch.com/"
        Constants.Api.userDefinedDomain = "https://default.test.sinch.com/"
        
        let initiationData = SeamlessVerificationInitiationData(
            identity: VerificationIdentity(endpoint: "+911234567890"),
            honourEarlyReject: true,
            custom: nil,
            reference: nil,
            metadata: nil
        )
        let request = try SeamlessVerificationRouter.initiateVerification(data: initiationData).asURLRequest()
        
        XCTAssertEqual(request.url?.host, "india.test.sinch.com")
        XCTAssertTrue(request.url?.absoluteString.contains("verification/v1/verifications") ?? false)
    }
    
    func testNonIndianNumberUsesDefaultBaseUrl() throws {
        let previousIndiaDomain = Constants.Api.userDefinedIndiaDomain
        let previousDomain = Constants.Api.userDefinedDomain
        defer {
            Constants.Api.userDefinedIndiaDomain = previousIndiaDomain
            Constants.Api.userDefinedDomain = previousDomain
        }
        
        Constants.Api.userDefinedIndiaDomain = "https://india.test.sinch.com/"
        Constants.Api.userDefinedDomain = "https://default.test.sinch.com/"
        
        let initiationData = SeamlessVerificationInitiationData(
            identity: VerificationIdentity(endpoint: "+48123456789"),
            honourEarlyReject: true,
            custom: nil,
            reference: nil,
            metadata: nil
        )
        let request = try SeamlessVerificationRouter.initiateVerification(data: initiationData).asURLRequest()
        
        XCTAssertEqual(request.url?.host, "default.test.sinch.com")
    }
    
    func testSeamlessHeaderInterceptorAddsDebugHeadersForIndianNumber() {
        let previousMsisdn = Constants.Api.Seamless.userDefinedDebugMsisdn
        let previousImsi = Constants.Api.Seamless.userDefinedDebugImsi
        defer {
            Constants.Api.Seamless.userDefinedDebugMsisdn = previousMsisdn
            Constants.Api.Seamless.userDefinedDebugImsi = previousImsi
        }
        
        Constants.Api.Seamless.userDefinedDebugMsisdn = "919876543210"
        Constants.Api.Seamless.userDefinedDebugImsi = "404451234567890"
        
        let headers = SeamlessHeaderInterceptor(number: "+911234567890").headers()
        
        #if DEBUG
        XCTAssertEqual(headers[SeamlessHeaderInterceptor.headerMsisdn], "919876543210")
        XCTAssertEqual(headers[SeamlessHeaderInterceptor.headerImsi], "404451234567890")
        #else
        XCTAssertTrue(headers.isEmpty)
        #endif
    }
    
    func testSeamlessHeaderInterceptorReturnsEmptyForNonIndianNumber() {
        let previousMsisdn = Constants.Api.Seamless.userDefinedDebugMsisdn
        let previousImsi = Constants.Api.Seamless.userDefinedDebugImsi
        defer {
            Constants.Api.Seamless.userDefinedDebugMsisdn = previousMsisdn
            Constants.Api.Seamless.userDefinedDebugImsi = previousImsi
        }
        
        Constants.Api.Seamless.userDefinedDebugMsisdn = "919876543210"
        Constants.Api.Seamless.userDefinedDebugImsi = "404451234567890"
        
        let headers = SeamlessHeaderInterceptor(number: "+48123456789").headers()
        XCTAssertTrue(headers.isEmpty)
    }
    
    func testSeamlessHeaderInterceptorReturnsEmptyForNilNumber() {
        let headers = SeamlessHeaderInterceptor(number: nil).headers()
        XCTAssertTrue(headers.isEmpty)
    }

}
