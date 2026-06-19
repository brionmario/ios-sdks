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

import XCTest
@testable import ThunderIDSwiftUI

final class ComponentTests: XCTestCase {

    // MARK: - ThunderIDI18n

    func testI18nResolvesDefaultString() {
        let i18n = ThunderIDI18n()
        XCTAssertEqual(i18n.resolve("signIn.button"), "Sign in")
    }

    func testI18nResolvesCustomBundle() {
        let i18n = ThunderIDI18n(bundles: ["en-US": ["signIn.button": "Log in"]])
        XCTAssertEqual(i18n.resolve("signIn.button"), "Log in")
    }

    func testI18nFallsBackToDefaultForMissingKey() {
        let i18n = ThunderIDI18n(bundles: ["en-US": [:]])
        XCTAssertEqual(i18n.resolve("signOut.button"), "Sign out")
    }

    func testI18nSetsLocale() {
        let i18n = ThunderIDI18n(
            bundles: ["fr-FR": ["signIn.button": "Se connecter"]],
            language: "en-US"
        )
        i18n.setLocale("fr-FR")
        XCTAssertEqual(i18n.activeLocale, "fr-FR")
        XCTAssertEqual(i18n.resolve("signIn.button"), "Se connecter")
    }

    func testI18nFallsBackThroughFallbackLocale() {
        let i18n = ThunderIDI18n(
            bundles: ["es-ES": ["signIn.button": "Iniciar sesión"]],
            language: "de-DE",
            fallbackLanguage: "es-ES"
        )
        XCTAssertEqual(i18n.resolve("signIn.button"), "Iniciar sesión")
    }

    func testI18nReturnsKeyForUnknown() {
        let i18n = ThunderIDI18n()
        XCTAssertEqual(i18n.resolve("not.a.real.key"), "not.a.real.key")
    }

    // MARK: - DefaultStrings

    func testDefaultStringsContainsAllExpectedKeys() {
        let requiredKeys = [
            "signIn.button", "signOut.button", "signUp.button",
            "userProfile.title", "userProfile.save",
            "languageSwitcher.title",
        ]
        for key in requiredKeys {
            XCTAssertNotNil(DefaultStrings.all[key], "Missing default string for key: \(key)")
        }
    }
}
