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

/// Renders `indicator` while the SDK is initializing or mid-operation (spec §8.4 Guards).
public struct Loading<Indicator: View>: View {
    @EnvironmentObject private var state: ThunderIDState
    private let indicator: Indicator

    public init(@ViewBuilder indicator: () -> Indicator) {
        self.indicator = indicator()
    }

    public var body: some View {
        if state.isLoading {
            indicator
        }
    }
}

public extension Loading where Indicator == ProgressView<EmptyView, EmptyView> {
    init() {
        self.init { ProgressView() }
    }
}
