// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ThunderID

/// A page of roles, rendered from the data it is given. Pair it with
/// ``ThunderIDState/rolesQuery(limit:offset:fetcher:)`` or any other source; ``RoleList`` does that for you.
public struct BaseRoleList: View {
    @EnvironmentObject private var i18n: ThunderIDI18n
    let roles: [RoleSummary]
    let isLoading: Bool
    let error: String?
    let title: String?
    let description: String?
    let limit: Int
    let offset: Int
    let totalResults: Int?
    let selectedRoleId: String?
    let onPageChange: ((Int) -> Void)?
    let onSelect: ((RoleSummary) -> Void)?
    let actions: AnyView?

    public init(
        roles: [RoleSummary],
        isLoading: Bool = false,
        error: String? = nil,
        title: String? = nil,
        description: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        totalResults: Int? = nil,
        selectedRoleId: String? = nil,
        onPageChange: ((Int) -> Void)? = nil,
        onSelect: ((RoleSummary) -> Void)? = nil,
        actions: AnyView? = nil
    ) {
        self.roles = roles
        self.isLoading = isLoading
        self.error = error
        self.title = title
        self.description = description
        self.limit = limit
        self.offset = offset
        self.totalResults = totalResults
        self.selectedRoleId = selectedRoleId
        self.onPageChange = onPageChange
        self.onSelect = onSelect
        self.actions = actions
    }

    public var body: some View {
        AdminSection(
            identifier: "admin-role-list",
            title: title ?? i18n.resolve("admin.roles.list.title"),
            description: description,
            actions: { actions },
            content: {
                AdminTable(
                    identifier: "admin-role-list",
                    rows: roles,
                    rowId: \.id,
                    isLoading: isLoading,
                    error: error,
                    emptyText: i18n.resolve("admin.roles.list.empty"),
                    selectedId: selectedRoleId,
                    onSelect: onSelect,
                    pagination: onPageChange.map {
                        AdminPagination(
                            i18n: i18n,
                            limit: limit,
                            offset: offset,
                            total: totalResults ?? roles.count,
                            onChange: $0
                        )
                    },
                    row: { role in
                        AdminRowLabel(
                            title: role.name,
                            details: [role.description ?? "", role.ouHandle ?? role.ouId]
                        )
                    },
                    i18n: i18n
                )
            }
        )
    }
}

/// A paginated list of the roles the signed-in user can see. Selecting a row calls `onSelect`;
/// the application decides where that leads.
public struct RoleList: View {
    @EnvironmentObject private var thunderState: ThunderIDState
    @EnvironmentObject private var i18n: ThunderIDI18n
    let limit: Int
    let title: String?
    let description: String?
    let selectedRoleId: String?
    let onSelect: ((RoleSummary) -> Void)?
    let actions: AnyView?
    @State private var offset = 0

    public init(
        limit: Int = 20,
        title: String? = nil,
        description: String? = nil,
        selectedRoleId: String? = nil,
        onSelect: ((RoleSummary) -> Void)? = nil,
        actions: AnyView? = nil
    ) {
        self.limit = limit
        self.title = title
        self.description = description
        self.selectedRoleId = selectedRoleId
        self.onSelect = onSelect
        self.actions = actions
    }

    public var body: some View {
        let state = thunderState
        AdminQueryReader(state.rolesQuery(limit: limit, offset: offset)) { query in
            BaseRoleList(
                roles: query.data?.roles ?? [],
                isLoading: query.isLoading,
                error: i18n.managementErrorMessage(query.error, fallbackKey: "admin.roles.list.error"),
                title: title,
                description: description,
                limit: limit,
                offset: offset,
                totalResults: query.data?.totalResults,
                selectedRoleId: selectedRoleId,
                onPageChange: { offset = $0 },
                onSelect: onSelect,
                actions: actions
            )
        }
        .id("\(offset)|\(limit)")
    }
}
