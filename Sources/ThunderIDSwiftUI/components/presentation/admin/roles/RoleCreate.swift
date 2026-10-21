// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ThunderID

/// A form for creating a role.
public struct BaseRoleCreate: View {
    @EnvironmentObject private var i18n: ThunderIDI18n
    let error: String?
    let isSubmitting: Bool
    let title: String?
    let description: String?
    let onCancel: (() -> Void)?
    let onSubmit: (NamedResourceSubmission) -> Void

    public init(
        error: String? = nil,
        isSubmitting: Bool = false,
        title: String? = nil,
        description: String? = nil,
        onCancel: (() -> Void)? = nil,
        onSubmit: @escaping (NamedResourceSubmission) -> Void
    ) {
        self.error = error
        self.isSubmitting = isSubmitting
        self.title = title
        self.description = description
        self.onCancel = onCancel
        self.onSubmit = onSubmit
    }

    public var body: some View {
        NamedResourceForm(
            i18n: i18n,
            identifier: "admin-role-create",
            keyPrefix: "admin.roles.create",
            error: error,
            isSubmitting: isSubmitting,
            title: title,
            description: description,
            onCancel: onCancel,
            onSubmit: onSubmit
        )
    }
}

/// Creates a role through the management API, in `ouId` or the signed-in user's own
/// organization unit when it is not given.
public struct RoleCreate: View {
    @EnvironmentObject private var thunderState: ThunderIDState
    let ouId: String?
    let title: String?
    let description: String?
    let onCancel: (() -> Void)?
    let onCreated: ((Role) -> Void)?

    public init(
        ouId: String? = nil,
        title: String? = nil,
        description: String? = nil,
        onCancel: (() -> Void)? = nil,
        onCreated: ((Role) -> Void)? = nil
    ) {
        self.ouId = ouId
        self.title = title
        self.description = description
        self.onCancel = onCancel
        self.onCreated = onCreated
    }

    public var body: some View {
        let state = thunderState
        AdminCreateHost(state: state, ouId: ouId, mutation: state.createRoleMutation()) { host in
            BaseRoleCreate(
                error: host.errorMessage(fallbackKey: "admin.roles.create.error"),
                isSubmitting: host.isSubmitting,
                title: title,
                description: description,
                onCancel: onCancel
            ) { submission in
                host.submit { ouId in
                    CreateRoleRequest(name: submission.name, ouId: ouId, description: submission.description)
                } onCreated: { onCreated?($0) }
            }
        }
    }
}
