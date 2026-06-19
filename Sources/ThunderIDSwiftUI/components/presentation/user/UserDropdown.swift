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

/// Avatar chip that expands to a menu with profile and sign-out actions (spec §8.4 Presentation).
public struct UserDropdown: View {
    @EnvironmentObject private var state: ThunderIDState
    @EnvironmentObject private var i18n: ThunderIDI18n
    public let onProfileTap: (() -> Void)?
    public let onSignOutComplete: (() -> Void)?

    public init(onProfileTap: (() -> Void)? = nil, onSignOutComplete: (() -> Void)? = nil) {
        self.onProfileTap = onProfileTap
        self.onSignOutComplete = onSignOutComplete
    }

    public var body: some View {
        BaseUserDropdown { user, isOpen, toggle, signOut in
            VStack(alignment: .trailing, spacing: 0) {
                Button(action: toggle) {
                    Text(initials(user))
                        .fontWeight(.bold)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(user?.displayName ?? i18n.resolve("user.anonymous"))
                .accessibilityHint("Opens user menu")

                if isOpen {
                    VStack(alignment: .leading, spacing: 0) {
                        if onProfileTap != nil {
                            Button(i18n.resolve("userProfile.title")) { onProfileTap?() }
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        Button(i18n.resolve("signOut.button")) { signOut() }
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
            }
        }
    }

    private func initials(_ user: User?) -> String {
        let name = user?.displayName ?? user?.username ?? user?.email ?? "?"
        let parts = name.split(separator: " ")
        if parts.count >= 2, let first = parts.first?.first, let last = parts.last?.first {
            return "\(first)\(last)".uppercased()
        }
        return name.prefix(1).uppercased()
    }
}

/// Unstyled base variant (spec §8.3).
public struct BaseUserDropdown<Content: View>: View {
    @EnvironmentObject private var state: ThunderIDState
    public let content: (User?, Bool, @escaping () -> Void, @escaping () -> Void) -> Content

    @State private var isOpen = false

    public init(@ViewBuilder content: @escaping (User?, Bool, @escaping () -> Void, @escaping () -> Void) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(state.user, isOpen, toggle, signOut)
    }

    private func toggle() { isOpen.toggle() }

    private func signOut() {
        Task {
            _ = try? await state.client.signOut()
            await state.refresh()
        }
    }
}
