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

/// Renders `content` only when the user is authenticated (spec §8.4 Guards).
public struct SignedIn<Content: View, Fallback: View>: View {
    @EnvironmentObject private var state: ThunderIDState
    private let content: Content
    private let fallback: Fallback

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder fallback: () -> Fallback
    ) {
        self.content = content()
        self.fallback = fallback()
    }

    public var body: some View {
        if state.isSignedIn {
            content
        } else {
            fallback
        }
    }
}

public extension SignedIn where Fallback == EmptyView {
    init(@ViewBuilder content: () -> Content) {
        self.init(content: content) { EmptyView() }
    }
}
