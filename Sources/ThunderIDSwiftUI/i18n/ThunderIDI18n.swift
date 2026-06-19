/*
 * Copyright (c) 2026, WSO2 LLC. (https://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

import Foundation

/// Resolves localized strings for ThunderIDSwiftUI components (spec §8.1 i18n).
///
/// Resolution order: custom bundle for active locale → custom bundle for fallback locale → English defaults.
public final class ThunderIDI18n: ObservableObject {
    @Published public private(set) var activeLocale: String

    private let bundles: [String: [String: String]]
    private let fallbackLocale: String
    private let storageKey: String

    public init(
        bundles: [String: [String: String]] = [:],
        language: String? = nil,
        fallbackLanguage: String = "en-US",
        storageKey: String = "thunder_locale"
    ) {
        self.bundles = bundles
        self.fallbackLocale = fallbackLanguage
        self.storageKey = storageKey
        let stored = UserDefaults.standard.string(forKey: storageKey)
        self.activeLocale = language ?? stored ?? fallbackLanguage
    }

    /// Returns the localized string for `key`, falling back through the chain.
    public func resolve(_ key: String) -> String {
        bundles[activeLocale]?[key]
            ?? bundles[fallbackLocale]?[key]
            ?? DefaultStrings.all[key]
            ?? key
    }

    /// Sets the active locale and persists it to UserDefaults.
    public func setLocale(_ locale: String) {
        guard locale != activeLocale else { return }
        UserDefaults.standard.set(locale, forKey: storageKey)
        activeLocale = locale
    }
}
