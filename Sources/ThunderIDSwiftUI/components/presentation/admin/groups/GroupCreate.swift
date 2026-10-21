// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ThunderID

/// What ``BaseGroupCreate`` and ``BaseRoleCreate`` submit.
public struct NamedResourceSubmission: Equatable {
    public let name: String
    /// `nil` when left blank.
    public let description: String?
}

/// A name and description form, shared by the group and role create components.
struct NamedResourceForm: View {
    let i18n: ThunderIDI18n
    let identifier: String
    let keyPrefix: String
    let error: String?
    let isSubmitting: Bool
    let title: String?
    let description: String?
    let onCancel: (() -> Void)?
    let onSubmit: (NamedResourceSubmission) -> Void

    @State private var name = ""
    @State private var resourceDescription = ""

    var body: some View {
        AdminSection(
            identifier: identifier,
            title: title ?? i18n.resolve("\(keyPrefix).title"),
            description: description
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if let error {
                    AdminErrorBanner(message: error)
                }
                AdminTextField(
                    label: i18n.resolve("\(keyPrefix).fields.name"),
                    name: "name",
                    isRequired: true,
                    text: $name
                )
                AdminTextField(
                    label: i18n.resolve("\(keyPrefix).fields.description"),
                    name: "description",
                    text: $resourceDescription
                )
                AdminFormActions(
                    i18n: i18n,
                    submitLabel: i18n.resolve("\(keyPrefix).submit"),
                    isSubmitting: isSubmitting,
                    canSubmit: !trimmedName.isEmpty,
                    onCancel: onCancel
                ) {
                    let text = resourceDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSubmit(NamedResourceSubmission(name: trimmedName, description: text.isEmpty ? nil : text))
                }
            }
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
}

/// A form for creating a group.
public struct BaseGroupCreate: View {
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
            identifier: "admin-group-create",
            keyPrefix: "admin.groups.create",
            error: error,
            isSubmitting: isSubmitting,
            title: title,
            description: description,
            onCancel: onCancel,
            onSubmit: onSubmit
        )
    }
}

/// Creates a group through the management API, in `ouId` or the signed-in user's own
/// organization unit when it is not given.
public struct GroupCreate: View {
    @EnvironmentObject private var thunderState: ThunderIDState
    let ouId: String?
    let title: String?
    let description: String?
    let onCancel: (() -> Void)?
    let onCreated: ((ManagedGroup) -> Void)?

    public init(
        ouId: String? = nil,
        title: String? = nil,
        description: String? = nil,
        onCancel: (() -> Void)? = nil,
        onCreated: ((ManagedGroup) -> Void)? = nil
    ) {
        self.ouId = ouId
        self.title = title
        self.description = description
        self.onCancel = onCancel
        self.onCreated = onCreated
    }

    public var body: some View {
        let state = thunderState
        AdminCreateHost(state: state, ouId: ouId, mutation: state.createGroupMutation()) { host in
            BaseGroupCreate(
                error: host.errorMessage(fallbackKey: "admin.groups.create.error"),
                isSubmitting: host.isSubmitting,
                title: title,
                description: description,
                onCancel: onCancel
            ) { submission in
                host.submit { ouId in
                    CreateGroupRequest(name: submission.name, ouId: ouId, description: submission.description)
                } onCreated: { onCreated?($0) }
            }
        }
    }
}
