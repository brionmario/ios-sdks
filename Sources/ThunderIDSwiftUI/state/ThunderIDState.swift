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
import ThunderID

/// Reactive auth state for SwiftUI views. Held as @StateObject in ThunderIDProvider.
@MainActor
public final class ThunderIDState: ObservableObject {
    @Published public private(set) var user: User?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var isInitialized: Bool = false
    @Published public private(set) var error: String?

    public let client: ThunderIDClient
    public let i18n: ThunderIDI18n

    public var isSignedIn: Bool { user != nil }

    init(client: ThunderIDClient, i18n: ThunderIDI18n) {
        self.client = client
        self.i18n = i18n
    }

    func initialize(config: ThunderIDConfig) async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await client.initialize(config: config)
            let signedIn = await (try? client.isSignedIn()) ?? false
            if signedIn {
                user = try? await client.getUser()
            }
            isInitialized = true
            error = nil
        } catch {
            self.error = error.localizedDescription
            isInitialized = true
        }
    }

    /// Refreshes sign-in state (call after signIn/signOut).
    public func refresh() async {
        guard isInitialized else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let signedIn = try await client.isSignedIn()
            user = signedIn ? try await client.getUser() : nil
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Switches the active UI locale.
    public func setLocale(_ locale: String) {
        i18n.setLocale(locale)
    }
}
