// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ThunderID

/// A page of users, rendered from the data it is given. Pair it with
/// ``ThunderIDState/usersQuery(limit:offset:filter:fetcher:)`` or any other source; ``UserList`` does that for you.
public struct BaseUserList<Content: View>: View {
    @EnvironmentObject private var i18n: ThunderIDI18n
    let users: [ManagedUser]
    let isLoading: Bool
    let error: String?
    let title: String?
    let description: String?
    let limit: Int
    let offset: Int
    let totalResults: Int?
    let selectedUserId: String?
    let onPageChange: ((Int) -> Void)?
    let onSelect: ((ManagedUser) -> Void)?
    let actions: AnyView?
    let content: ((AdminListState<ManagedUser>) -> Content)?

    init(
        users: [ManagedUser],
        isLoading: Bool = false,
        error: String? = nil,
        title: String? = nil,
        description: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        totalResults: Int? = nil,
        selectedUserId: String? = nil,
        onPageChange: ((Int) -> Void)? = nil,
        onSelect: ((ManagedUser) -> Void)? = nil,
        actions: AnyView? = nil,
        renderContent: ((AdminListState<ManagedUser>) -> Content)?
    ) {
        self.users = users
        self.isLoading = isLoading
        self.error = error
        self.title = title
        self.description = description
        self.limit = limit
        self.offset = offset
        self.totalResults = totalResults
        self.selectedUserId = selectedUserId
        self.onPageChange = onPageChange
        self.onSelect = onSelect
        self.actions = actions
        self.content = renderContent
    }

    /// - Parameter content: Renders custom UI in place of the default list, from the users, the loading and error
    ///   state, and the pagination and selection handlers.
    public init(
        users: [ManagedUser],
        isLoading: Bool = false,
        error: String? = nil,
        title: String? = nil,
        description: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        totalResults: Int? = nil,
        selectedUserId: String? = nil,
        onPageChange: ((Int) -> Void)? = nil,
        onSelect: ((ManagedUser) -> Void)? = nil,
        actions: AnyView? = nil,
        @ViewBuilder content: @escaping (AdminListState<ManagedUser>) -> Content
    ) {
        self.init(
            users: users,
            isLoading: isLoading,
            error: error,
            title: title,
            description: description,
            limit: limit,
            offset: offset,
            totalResults: totalResults,
            selectedUserId: selectedUserId,
            onPageChange: onPageChange,
            onSelect: onSelect,
            actions: actions,
            renderContent: content
        )
    }

    public var body: some View {
        if let content {
            content(renderState)
        } else {
            defaultBody
        }
    }

    private var renderState: AdminListState<ManagedUser> {
        AdminListState(
            rows: users,
            isLoading: isLoading,
            error: error,
            limit: limit,
            offset: offset,
            totalResults: totalResults ?? users.count,
            selectedId: selectedUserId,
            onPageChange: onPageChange,
            onSelect: onSelect
        )
    }

    @ViewBuilder
    private var defaultBody: some View {
        AdminSection(
            identifier: "admin-user-list",
            title: title ?? i18n.resolve("admin.users.list.title"),
            description: description,
            actions: { actions },
            content: {
                AdminTable(
                    identifier: "admin-user-list",
                    rows: users,
                    rowId: \.id,
                    isLoading: isLoading,
                    error: error,
                    emptyText: i18n.resolve("admin.users.list.empty"),
                    selectedId: selectedUserId,
                    onSelect: onSelect,
                    pagination: onPageChange.map {
                        AdminPagination(
                            i18n: i18n,
                            limit: limit,
                            offset: offset,
                            total: totalResults ?? users.count,
                            onChange: $0
                        )
                    },
                    row: { user in
                        HStack(spacing: 12) {
                            AdminAvatar(name: user.resolvedName, size: 28)
                            AdminRowLabel(title: user.resolvedName, details: [user.type, user.ouHandle ?? user.ouId])
                        }
                    },
                    i18n: i18n
                )
            }
        )
    }
}

public extension BaseUserList where Content == EmptyView {
    init(
        users: [ManagedUser],
        isLoading: Bool = false,
        error: String? = nil,
        title: String? = nil,
        description: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        totalResults: Int? = nil,
        selectedUserId: String? = nil,
        onPageChange: ((Int) -> Void)? = nil,
        onSelect: ((ManagedUser) -> Void)? = nil,
        actions: AnyView? = nil
    ) {
        self.init(
            users: users,
            isLoading: isLoading,
            error: error,
            title: title,
            description: description,
            limit: limit,
            offset: offset,
            totalResults: totalResults,
            selectedUserId: selectedUserId,
            onPageChange: onPageChange,
            onSelect: onSelect,
            actions: actions,
            renderContent: nil
        )
    }
}

/// A paginated list of the users the signed-in user can see. Selecting a row calls `onSelect`;
/// the application decides where that leads.
public struct UserList<Content: View>: View {
    @EnvironmentObject private var thunderState: ThunderIDState
    @EnvironmentObject private var i18n: ThunderIDI18n
    let filter: String?
    let limit: Int
    let title: String?
    let description: String?
    let selectedUserId: String?
    let onSelect: ((ManagedUser) -> Void)?
    let actions: AnyView?
    @State private var offset = 0

    let content: ((AdminListState<ManagedUser>) -> Content)?

    init(
        filter: String? = nil,
        limit: Int = 20,
        title: String? = nil,
        description: String? = nil,
        selectedUserId: String? = nil,
        onSelect: ((ManagedUser) -> Void)? = nil,
        actions: AnyView? = nil,
        renderContent: ((AdminListState<ManagedUser>) -> Content)?
    ) {
        self.filter = filter
        self.limit = limit
        self.title = title
        self.description = description
        self.selectedUserId = selectedUserId
        self.onSelect = onSelect
        self.actions = actions
        self.content = renderContent
    }

    /// - Parameter content: Renders custom UI in place of the default list. See ``BaseUserList``.
    public init(
        filter: String? = nil,
        limit: Int = 20,
        title: String? = nil,
        description: String? = nil,
        selectedUserId: String? = nil,
        onSelect: ((ManagedUser) -> Void)? = nil,
        actions: AnyView? = nil,
        @ViewBuilder content: @escaping (AdminListState<ManagedUser>) -> Content
    ) {
        self.init(
            filter: filter,
            limit: limit,
            title: title,
            description: description,
            selectedUserId: selectedUserId,
            onSelect: onSelect,
            actions: actions,
            renderContent: content
        )
    }

    public var body: some View {
        let state = thunderState
        AdminQueryReader(state.usersQuery(limit: limit, offset: offset, filter: filter)) { query in
            BaseUserList(
                users: query.data?.users ?? [],
                isLoading: query.isLoading,
                error: i18n.managementErrorMessage(query.error, fallbackKey: "admin.users.list.error"),
                title: title,
                description: description,
                limit: limit,
                offset: offset,
                totalResults: query.data?.totalResults,
                selectedUserId: selectedUserId,
                onPageChange: { offset = $0 },
                onSelect: onSelect,
                actions: actions,
                renderContent: content
            )
        }
        .id("\(offset)|\(limit)|\(filter ?? "")")
    }
}

public extension UserList where Content == EmptyView {
    init(
        filter: String? = nil,
        limit: Int = 20,
        title: String? = nil,
        description: String? = nil,
        selectedUserId: String? = nil,
        onSelect: ((ManagedUser) -> Void)? = nil,
        actions: AnyView? = nil
    ) {
        self.init(
            filter: filter,
            limit: limit,
            title: title,
            description: description,
            selectedUserId: selectedUserId,
            onSelect: onSelect,
            actions: actions,
            renderContent: nil
        )
    }
}
