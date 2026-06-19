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
import ThunderIDSwiftUI

private enum AuthMode {
    case signIn, signUp
}

struct AuthView: View {
    @EnvironmentObject private var state: ThunderIDState
    private var applicationId: String { (try? state.client.getConfiguration())?.applicationId ?? "" }
    @State private var mode: AuthMode = .signIn

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ── Header ────────────────────────────────────────────────
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 72, height: 72)
                        Image(systemName: "house.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    Text("ACME Booking")
                        .font(.title2).bold()
                    Text("Find your perfect stay")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 40)

                // ── Mode toggle ───────────────────────────────────────────
                Picker("Auth mode", selection: $mode) {
                    Text("Sign In").tag(AuthMode.signIn)
                    Text("Create Account").tag(AuthMode.signUp)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 28)

                // ── Form ──────────────────────────────────────────────────
                Group {
                    if mode == .signIn {
                        SignIn(applicationId: applicationId)
                    } else {
                        SignUp(applicationId: applicationId)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
        }
    }
}
