// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ThunderID

/// A page of groups, rendered from the data it is given. Pair it with
/// ``ThunderIDState/groupsQuery(limit:offset:fetcher:)`` or any other source; ``GroupList`` does that for you.
public struct BaseGroupList: View {
    @EnvironmentObject private var i18n: ThunderIDI18n
    let groups: [ManagedGroup]
    let isLoading: Bool
    let error: String?
    let title: String?
    let description: String?
    let limit: Int
    let offset: Int
    let totalResults: Int?
    let selectedGroupId: String?
    let onPageChange: ((Int) -> Void)?
    let onSelect: ((ManagedGroup) -> Void)?
    let actions: AnyView?

    public init(
        groups: [ManagedGroup],
        isLoading: Bool = false,
        error: String? = nil,
        title: String? = nil,
        description: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        totalResults: Int? = nil,
        selectedGroupId: String? = nil,
        onPageChange: ((Int) -> Void)? = nil,
        onSelect: ((ManagedGroup) -> Void)? = nil,
        actions: AnyView? = nil
    ) {
        self.groups = groups
        self.isLoading = isLoading
        self.error = error
        self.title = title
        self.description = description
        self.limit = limit
        self.offset = offset
        self.totalResults = totalResults
        self.selectedGroupId = selectedGroupId
        self.onPageChange = onPageChange
        self.onSelect = onSelect
        self.actions = actions
    }

    public var body: some View {
        AdminSection(
            identifier: "admin-group-list",
            title: title ?? i18n.resolve("admin.groups.list.title"),
            description: description,
            actions: { actions },
            content: {
                AdminTable(
                    identifier: "admin-group-list",
                    rows: groups,
                    rowId: \.id,
                    isLoading: isLoading,
                    error: error,
                    emptyText: i18n.resolve("admin.groups.list.empty"),
                    selectedId: selectedGroupId,
                    onSelect: onSelect,
                    pagination: onPageChange.map {
                        AdminPagination(
                            i18n: i18n,
                            limit: limit,
                            offset: offset,
                            total: totalResults ?? groups.count,
                            onChange: $0
                        )
                    },
                    row: { group in
                        AdminRowLabel(
                            title: group.name,
                            details: [group.description ?? "", group.ouHandle ?? group.ouId]
                        )
                    },
                    i18n: i18n
                )
            }
        )
    }
}

/// A paginated list of the groups the signed-in user can see. Selecting a row calls `onSelect`;
/// the application decides where that leads.
public struct GroupList: View {
    @EnvironmentObject private var thunderState: ThunderIDState
    @EnvironmentObject private var i18n: ThunderIDI18n
    let limit: Int
    let title: String?
    let description: String?
    let selectedGroupId: String?
    let onSelect: ((ManagedGroup) -> Void)?
    let actions: AnyView?
    @State private var offset = 0

    public init(
        limit: Int = 20,
        title: String? = nil,
        description: String? = nil,
        selectedGroupId: String? = nil,
        onSelect: ((ManagedGroup) -> Void)? = nil,
        actions: AnyView? = nil
    ) {
        self.limit = limit
        self.title = title
        self.description = description
        self.selectedGroupId = selectedGroupId
        self.onSelect = onSelect
        self.actions = actions
    }

    public var body: some View {
        let state = thunderState
        AdminQueryReader(state.groupsQuery(limit: limit, offset: offset)) { query in
            BaseGroupList(
                groups: query.data?.groups ?? [],
                isLoading: query.isLoading,
                error: i18n.managementErrorMessage(query.error, fallbackKey: "admin.groups.list.error"),
                title: title,
                description: description,
                limit: limit,
                offset: offset,
                totalResults: query.data?.totalResults,
                selectedGroupId: selectedGroupId,
                onPageChange: { offset = $0 },
                onSelect: onSelect,
                actions: actions
            )
        }
        .id("\(offset)|\(limit)")
    }
}
