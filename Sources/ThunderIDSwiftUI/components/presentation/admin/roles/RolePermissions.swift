// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ThunderID

/// The permissions a role grants, grouped by resource server, rendered from the data it is given.
public struct BaseRolePermissions: View {
    @EnvironmentObject private var i18n: ThunderIDI18n
    let permissions: [RoleResourcePermissions]
    let resourceServerNames: [String: String]
    let isLoading: Bool
    let error: String?
    let title: String?
    let description: String?

    /// - Parameter resourceServerNames: Display names keyed by resource server identifier. A
    ///   resource server without one is shown by its identifier.
    public init(
        permissions: [RoleResourcePermissions],
        resourceServerNames: [String: String] = [:],
        isLoading: Bool = false,
        error: String? = nil,
        title: String? = nil,
        description: String? = nil
    ) {
        self.permissions = permissions
        self.resourceServerNames = resourceServerNames
        self.isLoading = isLoading
        self.error = error
        self.title = title
        self.description = description
    }

    public var body: some View {
        AdminSection(
            identifier: "admin-role-permissions",
            title: title ?? i18n.resolve("admin.roles.permissions.title"),
            description: description
        ) {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        let granted = permissions.filter { !$0.permissions.isEmpty }
        if isLoading {
            AdminLoadingRow(label: i18n.resolve("admin.common.loading"))
        } else if let error {
            AdminErrorBanner(message: error)
        } else if granted.isEmpty {
            Text(i18n.resolve("admin.roles.permissions.empty"))
                .foregroundColor(.secondary)
        } else {
            ForEach(granted, id: \.resourceServerId) { entry in
                let name = resourceServerNames[entry.resourceServerId] ?? entry.resourceServerId
                AdminPanel(title: name) {
                    AdminChipList(
                        label: name,
                        emptyText: i18n.resolve("admin.roles.permissions.empty"),
                        items: entry.permissions.map { ($0, $0) }
                    )
                }
            }
        }
    }
}

/// The permissions a role grants, loaded through the management API.
public struct RolePermissions: View {
    @EnvironmentObject private var thunderState: ThunderIDState
    @EnvironmentObject private var i18n: ThunderIDI18n
    let roleId: String
    let resourceServerNames: [String: String]
    let title: String?
    let description: String?

    public init(
        roleId: String,
        resourceServerNames: [String: String] = [:],
        title: String? = nil,
        description: String? = nil
    ) {
        self.roleId = roleId
        self.resourceServerNames = resourceServerNames
        self.title = title
        self.description = description
    }

    public var body: some View {
        let state = thunderState
        AdminQueryReader(state.roleQuery(id: roleId)) { role in
            BaseRolePermissions(
                permissions: role.data?.permissions ?? [],
                resourceServerNames: resourceServerNames,
                isLoading: role.isLoading,
                error: i18n.managementErrorMessage(role.error, fallbackKey: "admin.roles.permissions.error"),
                title: title,
                description: description
            )
        }
        .id(roleId)
    }
}
