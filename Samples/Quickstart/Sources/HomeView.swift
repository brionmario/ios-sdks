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

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject private var state: ThunderIDState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreTabView { selectedTab = 4 }
                .tabItem { Label("Explore", systemImage: "safari") }
                .tag(0)
            PlaceholderTabView(label: "Saved", systemImage: "heart")
                .tabItem { Label("Saved", systemImage: "heart") }
                .tag(1)
            PlaceholderTabView(label: "Trips", systemImage: "suitcase")
                .tabItem { Label("Trips", systemImage: "suitcase") }
                .tag(2)
            PlaceholderTabView(label: "Inbox", systemImage: "bubble.left")
                .tabItem { Label("Inbox", systemImage: "bubble.left") }
                .tag(3)
            ProfileTabView()
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(4)
        }
        .task {
            #if DEBUG
            await logAccessToken()
            #endif
        }
    }

    private func logAccessToken() async {
        do {
            let token = try await state.client.getAccessToken()
            print("[HomeView] access token: \(token)")
            print("[HomeView] token payload: \(decodeJwtPayload(token))")
        } catch {
            print("[HomeView] could not get access token: \(error)")
        }
    }

    private func decodeJwtPayload(_ token: String) -> String {
        let parts = token.split(separator: ".").map(String.init)
        guard parts.count == 3 else { return "(not a JWT)" }
        var base64 = parts[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64),
              let json = String(data: data, encoding: .utf8) else {
            return "(decode error)"
        }
        return json
    }
}

// MARK: - Explore Tab

private struct ExploreTabView: View {
    @EnvironmentObject private var state: ThunderIDState
    let onProfileTap: () -> Void
    @State private var categoryIndex = 0
    @State private var sortIndex = 0

    private static let categories = ["Stays", "Experiences", "Adventures", "Luxe"]
    private static let categoryIcons = ["house", "map", "mountain.2", "diamond"]
    private static let sorts = ["Popular", "Near", "Best Price"]

    private static let listings = [
        Listing(
            title: "Cozy Mountain Retreat",
            location: "Aspen, Colorado",
            price: 189,
            rating: 4.92,
            imageUrl: "https://picsum.photos/seed/acme1/400/280"
        ),
        Listing(
            title: "Beachfront Villa",
            location: "Malibu, California",
            price: 342,
            rating: 4.87,
            imageUrl: "https://picsum.photos/seed/acme2/400/280"
        ),
        Listing(
            title: "City Centre Loft",
            location: "New York, NY",
            price: 215,
            rating: 4.78,
            imageUrl: "https://picsum.photos/seed/acme3/400/280"
        ),
        Listing(
            title: "Lakeside Cabin",
            location: "Lake Tahoe, Nevada",
            price: 156,
            rating: 4.95,
            imageUrl: "https://picsum.photos/seed/acme4/400/280"
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topBar
                welcomeHeading
                searchBar
                categoryChips
                sortTabs
                listingsGrid
            }
        }
        .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
    }

    private var topBar: some View {
        HStack {
            Image(systemName: "house.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 22))
            Text("ACME Booking")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.accentColor)
            Spacer()
            UserAvatarView(user: state.user, radius: 18)
                .onTapGesture { onProfileTap() }
            Spacer().frame(width: 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private var welcomeHeading: some View {
        Text("Where Would you\nLike to Stay, \(firstName)?")
            .font(.title2)
            .bold()
            .padding(.horizontal, 24)
            .padding(.top, 24)
    }

    private var firstName: String {
        if let given = state.user?.claims?["given_name"]?.value as? String, !given.isEmpty {
            return given
        }
        return state.user?.displayName?.components(separatedBy: " ").first ?? "there"
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            Text("Search destinations...")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.12))
        .clipShape(Capsule())
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<Self.categories.count, id: \.self) { idx in
                    let selected = idx == categoryIndex
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selected ? Color.accentColor : Color.secondary.opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: Self.categoryIcons[idx])
                                .foregroundColor(selected ? .white : .secondary)
                        }
                        .animation(.easeInOut(duration: 0.2), value: selected)
                        Text(Self.categories[idx])
                            .font(.system(size: 11, weight: selected ? .bold : .regular))
                            .foregroundColor(selected ? .accentColor : .secondary)
                    }
                    .onTapGesture { categoryIndex = idx }
                }
            }
            .padding(.leading, 24)
            .padding(.trailing, 12)
        }
        .frame(height: 84)
        .padding(.top, 20)
    }

    private var sortTabs: some View {
        HStack(spacing: 0) {
            ForEach(0..<Self.sorts.count, id: \.self) { idx in
                let selected = idx == sortIndex
                VStack(alignment: .leading, spacing: 3) {
                    Text(Self.sorts[idx])
                        .font(.system(size: 15, weight: selected ? .bold : .regular))
                        .foregroundColor(selected ? .primary : .secondary)
                    if selected {
                        Color.accentColor
                            .frame(width: 28, height: 2)
                            .cornerRadius(1)
                    } else {
                        Color.clear.frame(height: 2)
                    }
                }
                .onTapGesture { sortIndex = idx }
                .padding(.trailing, idx < Self.sorts.count - 1 ? 20 : 0)
            }
            Spacer()
            Text("See More")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private var listingsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Self.listings, id: \.title) { listing in
                ListingCardView(listing: listing)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - Profile Tab

private struct ProfileTabView: View {
    @EnvironmentObject private var state: ThunderIDState
    @State private var showEditProfile = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                profileCard
                    .padding(.horizontal, 24)
                statsCard
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                featureCards
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                editProfileButton
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                signOutButton
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showEditProfile) {
            NavigationStack {
                ScrollView {
                    UserProfile { showEditProfile = false }
                        .padding(24)
                }
                .navigationTitle("Edit Profile")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showEditProfile = false }
                    }
                }
            }
            .presentationDetents([.large])
        }
    }

    private var header: some View {
        HStack {
            Text("Profile")
                .font(.title2).bold()
            Spacer()
            Button { } label: {
                Image(systemName: "bell")
                    .font(.system(size: 20))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }

    private var displayName: String {
        let given = state.user?.claims?["given_name"]?.value as? String ?? ""
        let family = state.user?.claims?["family_name"]?.value as? String ?? ""
        let full = [given, family].filter { !$0.isEmpty }.joined(separator: " ")
        return full.isEmpty ? (state.user?.username ?? "Guest") : full
    }

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                UserAvatarView(user: state.user, radius: 40)
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.title3).bold()
                Text("Los Angeles, CA")
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(24)
        .background(.background)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            StatItemView(value: "24", label: "Trips")
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: 44)
            StatItemView(value: "22", label: "Reviews")
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: 44)
            StatItemView(value: "2", label: "Years on ACME")
        }
        .padding(.vertical, 20)
        .background(.background)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    private var featureCards: some View {
        HStack(spacing: 12) {
            FeatureCardView(
                label: "Past trips",
                imageUrl: "https://picsum.photos/seed/trips/300/200",
                isNew: true
            )
            FeatureCardView(
                label: "Connections",
                imageUrl: "https://picsum.photos/seed/connect/300/200",
                isNew: true
            )
        }
    }

    private var editProfileButton: some View {
        Button { showEditProfile = true } label: {
            Label("Edit Profile", systemImage: "pencil")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var signOutButton: some View {
        SignOutButton()
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Placeholder Tab

private struct PlaceholderTabView: View {
    let label: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            Text(label)
                .font(.title2)
            Text("Coming soon")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
