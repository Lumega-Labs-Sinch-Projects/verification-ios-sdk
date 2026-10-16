//
//  Environments.swift
//  VerificationSample
//
//  Created by Aleksander Wojcik on 17/08/2020.
//  Copyright © 2020 Aleksander Wojcik. All rights reserved.
//

import Foundation

struct Environment: Equatable {
    let domain: String
    let name: String
    let appKey: String
    let appSecret: String
    let isCustom: Bool

    init(domain: String, name: String, appKey: String, appSecret: String, isCustom: Bool = false) {
        self.domain = domain
        self.name = name
        self.appKey = appKey
        self.appSecret = appSecret
        self.isCustom = isCustom
    }

    static let customName = "Custom"
}

/// Global / regional API environments (maps to Android AppConfig).
let Environments: [Environment] = [
    Environment(domain: "https://verification.api.sinch.com/", name: "Default", appKey: "<YOUR APP KEY>", appSecret: "<YOUR APP SECRET>"),
    Environment(domain: "https://dc-usw2-std.verification.api.sinch.com/", name: "US", appKey: "<YOUR APP KEY>", appSecret: "<YOUR APP SECRET>"),
    Environment(domain: "https://dc-aps1-std.verification.api.sinch.com/", name: "APS", appKey: "<YOUR APP KEY>", appSecret: "<YOUR APP SECRET>"),
    Environment(domain: "https://dc-euc1-std.verification.api.sinch.com/", name: "EU", appKey: "<YOUR APP KEY>", appSecret: "<YOUR APP SECRET>"),
    Environment(domain: "https://verificationapi-v1-01.sinchlab.com/", name: "Ftest1", appKey: "<YOUR APP KEY>", appSecret: "<YOUR APP SECRET>"),
    Environment(domain: "https://ft1-verification.api.sinchlab.com/", name: "Ftest1 BROK", appKey: "<YOUR APP KEY>", appSecret: "<YOUR APP SECRET>"),
    Environment(domain: "https://verificationapi-v1-02.sinchlab.com/", name: "Ftest2", appKey: "<YOUR APP KEY>", appSecret: "<YOUR APP SECRET>"),
    Environment(domain: "https://ft2-verification.api.sinchlab.com/", name: "Ftest2 BROK", appKey: "<YOUR APP KEY>", appSecret: "<YOUR APP SECRET>"),
    Environment(domain: "https://verification.api.sinch.com/", name: Environment.customName, appKey: "<YOUR APP KEY>", appSecret: "<YOUR APP SECRET>", isCustom: true)
]

/// Preset India API environments for seamless verification.
/// URLs align with Android `IndiaEnv` / verification-seamless BuildConfig values.
enum IndiaEnv: String, CaseIterable {
    case stage = "Stage"
    case uat = "UAT"
    case prod = "Prod"

    var domain: String {
        switch self {
        case .stage: return "https://dkrs.aclwhatsapp.com/"
        case .uat: return "https://smv.sinchconverse.com/"
        case .prod: return "https://smvprod.sinchconverse.com/"
        }
    }

    /// Default India app key hint (editable in Settings). Keep empty in source — set via Settings UI.
    var defaultAppKey: String {
        ""
    }

    static func fromName(_ name: String) -> IndiaEnv {
        IndiaEnv(rawValue: name) ?? .stage
    }
}

/// Where seamless verification routes non-Indian numbers.
/// Indian numbers (+91) always use the India endpoint.
enum DefaultRouting: String, CaseIterable {
    case global = "Global"
    case india = "India"

    var routeNonIndianNumbers: Bool { self == .india }

    static func fromName(_ name: String) -> DefaultRouting {
        DefaultRouting(rawValue: name) ?? .global
    }
}
