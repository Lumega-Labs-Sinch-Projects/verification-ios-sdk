//
//  IndiaAppKeyInterceptor.swift
//  VerificationSample
//
//  Sample-only interceptor: Application auth for India-host requests.
//  Covers hosts like Stage (aclwhatsapp.com) that AppKeyAuthorizationMethod skips.
//

import Alamofire
import Foundation

final class IndiaAppKeyInterceptor: RequestInterceptor {

    private let indiaHost: String
    private let appKey: String

    init(indiaHost: String, appKey: String) {
        self.indiaHost = indiaHost
        self.appKey = appKey
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard !appKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let requestHost = urlRequest.url?.host,
              let indiaURL = URL(string: indiaHost),
              let expectedHost = indiaURL.host,
              requestHost.caseInsensitiveCompare(expectedHost) == .orderedSame else {
            completion(.success(urlRequest))
            return
        }

        var request = urlRequest
        request.setValue("Application \(appKey)", forHTTPHeaderField: "Authorization")
        completion(.success(request))
    }
}
