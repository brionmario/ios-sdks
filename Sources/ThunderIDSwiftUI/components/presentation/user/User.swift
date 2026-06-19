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
import ThunderID

/// Read-only display of the current user (spec §8.4 Presentation).
public struct UserObject: View {
    @EnvironmentObject private var state: ThunderIDState
    @EnvironmentObject private var i18n: ThunderIDI18n

    public init() {}

    public var body: some View {
        BaseUserObject { user in
            Text(user?.displayName ?? user?.username ?? i18n.resolve("user.anonymous"))
                .accessibilityLabel(user?.displayName ?? i18n.resolve("user.anonymous"))
        }
    }
}

/// Unstyled base variant (spec §8.3).
public struct BaseUserObject<Content: View>: View {
    @EnvironmentObject private var state: ThunderIDState
    public let content: (User?) -> Content

    public init(@ViewBuilder content: @escaping (User?) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(state.user)
    }
}
