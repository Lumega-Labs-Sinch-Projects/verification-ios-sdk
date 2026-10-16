//
//  SampleConfigStore.swift
//  VerificationSample
//
//  Sample-only persistence and SDK override application (mirrors Android SharedPrefsManager).
//

import Foundation
import Verification

extension Notification.Name {
    static let sampleConfigDidChange = Notification.Name("sampleConfigDidChange")
}

/// Persisted sample-app configuration for global + India endpoints.
final class SampleConfigStore {

    static let shared = SampleConfigStore()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let usedEnvName = "sample_used_env_name"
        static let appKeyPrefix = "sample_app_key_"
        static let envDomainPrefix = "sample_env_domain_"
        static let indiaEnv = "sample_india_env"
        static let defaultRouting = "sample_default_routing"
        static let indiaAppKey = "sample_india_app_key"
    }

    private init() {}

    // MARK: - Global environment

    var usedEnvironmentName: String {
        get {
            defaults.string(forKey: Keys.usedEnvName) ?? Environments[0].name
        }
        set {
            defaults.set(newValue, forKey: Keys.usedEnvName)
        }
    }

    var usedConfig: Environment {
        get {
            let name = usedEnvironmentName
            let preset = Environments.first { $0.name == name } ?? Environments[0]
            return Environment(
                domain: domain(for: name, fallback: preset.domain),
                name: name,
                appKey: appKey(for: name, fallback: preset.appKey),
                appSecret: preset.appSecret,
                isCustom: name == Environment.customName
            )
        }
        set {
            usedEnvironmentName = newValue.name
            setAppKey(newValue.appKey, for: newValue.name)
            setDomain(newValue.domain, for: newValue.name)
        }
    }

    func selectEnvironment(named name: String) {
        usedEnvironmentName = name
        applyToSDK()
        notifyChanged()
    }

    func updateCurrentAppKey(_ newKey: String) {
        setAppKey(newKey, for: usedEnvironmentName)
        applyToSDK()
        notifyChanged()
    }

    @discardableResult
    func updateCurrentBaseURL(_ newURL: String) -> Bool {
        guard usedConfig.isCustom else { return false }
        guard Self.isValidAPIBaseURL(newURL) else { return false }
        setDomain(Self.normalizedAPIBaseURL(newURL), for: usedEnvironmentName)
        applyToSDK()
        notifyChanged()
        return true
    }

    // MARK: - India settings

    var indiaEnv: IndiaEnv {
        get { IndiaEnv.fromName(defaults.string(forKey: Keys.indiaEnv) ?? IndiaEnv.stage.rawValue) }
        set { defaults.set(newValue.rawValue, forKey: Keys.indiaEnv) }
    }

    var defaultRouting: DefaultRouting {
        get { DefaultRouting.fromName(defaults.string(forKey: Keys.defaultRouting) ?? DefaultRouting.global.rawValue) }
        set { defaults.set(newValue.rawValue, forKey: Keys.defaultRouting) }
    }

    var indiaAppKey: String {
        get {
            if let stored = defaults.string(forKey: Keys.indiaAppKey) {
                return stored
            }
            return indiaEnv.defaultAppKey
        }
        set { defaults.set(newValue, forKey: Keys.indiaAppKey) }
    }

    var indiaApiHost: String { indiaEnv.domain }

    func updateIndiaEnv(_ env: IndiaEnv) {
        indiaEnv = env
        applyToSDK()
        notifyChanged()
    }

    func updateDefaultRouting(_ routing: DefaultRouting) {
        defaultRouting = routing
        applyToSDK()
        notifyChanged()
    }

    func updateIndiaAppKey(_ key: String) {
        indiaAppKey = key
        applyToSDK()
        notifyChanged()
    }

    // MARK: - Apply to SDK public overrides

    /// Applies persisted domains to SDK `Constants.Api` overrides.
    func applyToSDK() {
        let config = usedConfig
        let indiaHost = indiaApiHost

        Constants.Api.userDefinedIndiaDomain = indiaHost

        if defaultRouting.routeNonIndianNumbers {
            // Sample-only approximation of Android routeNonIndianNumbers:
            // force the global domain to the India host as well.
            Constants.Api.userDefinedDomain = indiaHost
        } else {
            Constants.Api.userDefinedDomain = config.domain
        }
    }

    /// Authorization method for the current global app key (AppKey style, matching Android sample).
    func authorizationMethod() -> AuthorizationMethod {
        AppKeyAuthorizationMethod(appKey: usedConfig.appKey)
    }

    /// Interceptor that attaches India Application auth for India-host requests.
    func indiaAppKeyInterceptor() -> IndiaAppKeyInterceptor {
        IndiaAppKeyInterceptor(indiaHost: indiaApiHost, appKey: indiaAppKey)
    }

    // MARK: - Helpers

    private func appKey(for name: String, fallback: String) -> String {
        defaults.string(forKey: Keys.appKeyPrefix + name) ?? fallback
    }

    private func setAppKey(_ key: String, for name: String) {
        defaults.set(key, forKey: Keys.appKeyPrefix + name)
    }

    private func domain(for name: String, fallback: String) -> String {
        defaults.string(forKey: Keys.envDomainPrefix + name) ?? fallback
    }

    private func setDomain(_ domain: String, for name: String) {
        defaults.set(domain, forKey: Keys.envDomainPrefix + name)
    }

    private func notifyChanged() {
        NotificationCenter.default.post(name: .sampleConfigDidChange, object: self)
    }

    static func isValidAPIBaseURL(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else { return false }
        return (scheme == "https" || scheme == "http") && url.host != nil
    }

    static func normalizedAPIBaseURL(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasSuffix("/") ? trimmed : trimmed + "/"
    }
}
