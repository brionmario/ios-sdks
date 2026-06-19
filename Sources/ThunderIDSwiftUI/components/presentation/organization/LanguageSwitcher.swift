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

import SwiftUI

/// Locale picker that updates active language for component labels (spec §8.4 Presentation).
public struct LanguageSwitcher: View {
    @EnvironmentObject private var i18n: ThunderIDI18n
    public let locales: [String]

    public init(locales: [String] = []) { self.locales = locales }

    public var body: some View {
        BaseLanguageSwitcher(locales: locales) { available, active, select in
            VStack(alignment: .leading, spacing: 0) {
                ForEach(available, id: \.self) { locale in
                    Button {
                        select(locale)
                    } label: {
                        HStack {
                            Text(locale)
                            if locale == active {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .accessibilityLabel(locale)
                    .accessibilityAddTraits(locale == active ? .isSelected : [])
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
    }
}

/// Unstyled base variant (spec §8.3).
public struct BaseLanguageSwitcher<Content: View>: View {
    @EnvironmentObject private var state: ThunderIDState
    @EnvironmentObject private var i18n: ThunderIDI18n
    public let locales: [String]
    public let content: ([String], String, @escaping (String) -> Void) -> Content

    public init(
        locales: [String] = [],
        @ViewBuilder content: @escaping ([String], String, @escaping (String) -> Void) -> Content
    ) {
        self.locales = locales
        self.content = content
    }

    public var body: some View {
        content(locales.isEmpty ? ["en-US"] : locales, i18n.activeLocale) { locale in
            state.setLocale(locale)
        }
    }
}
