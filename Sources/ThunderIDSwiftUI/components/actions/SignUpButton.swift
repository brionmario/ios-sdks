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

/// Button that initiates the sign-up flow (spec §8.4 Actions).
public struct SignUpButton: View {
    @EnvironmentObject private var i18n: ThunderIDI18n
    public let onTap: (() -> Void)?

    public init(onTap: (() -> Void)? = nil) { self.onTap = onTap }

    public var body: some View {
        BaseSignUpButton(label: i18n.resolve("signUp.button")) { onTap?() }
    }
}

/// Unstyled base variant (spec §8.3).
public struct BaseSignUpButton: View {
    public let label: String
    public let action: () -> Void

    public init(label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label)
        }
        .accessibilityLabel(label)
        .frame(minWidth: 44, minHeight: 44)
    }
}
