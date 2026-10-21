// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ThunderID

/// What ``BaseAgentCreate`` submits.
public struct AgentCreateSubmission: Equatable {
    public let name: String
    public let type: String
    /// `nil` when left blank.
    public let description: String?
}

/// A form for registering an agent, rendered from the agent types it is given.
public struct BaseAgentCreate: View {
    @EnvironmentObject private var i18n: ThunderIDI18n
    let agentTypes: [AdminOption]
    let error: String?
    let isSubmitting: Bool
    let title: String?
    let description: String?
    let onCancel: (() -> Void)?
    let onSubmit: (AgentCreateSubmission) -> Void

    @State private var name = ""
    @State private var chosenType = ""
    @State private var agentDescription = ""

    public init(
        agentTypes: [AdminOption],
        error: String? = nil,
        isSubmitting: Bool = false,
        title: String? = nil,
        description: String? = nil,
        onCancel: (() -> Void)? = nil,
        onSubmit: @escaping (AgentCreateSubmission) -> Void
    ) {
        self.agentTypes = agentTypes
        self.error = error
        self.isSubmitting = isSubmitting
        self.title = title
        self.description = description
        self.onCancel = onCancel
        self.onSubmit = onSubmit
    }

    private var type: String { chosenType.isEmpty ? (agentTypes.first?.value ?? "") : chosenType }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    public var body: some View {
        AdminSection(
            identifier: "admin-agent-create",
            title: title ?? i18n.resolve("admin.agents.create.title"),
            description: description
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if let error {
                    AdminErrorBanner(message: error)
                }
                AdminTextField(
                    label: i18n.resolve("admin.agents.create.fields.name"),
                    name: "name",
                    isRequired: true,
                    text: $name
                )
                AdminPicker(
                    label: i18n.resolve("admin.agents.create.fields.type"),
                    name: "type",
                    options: agentTypes,
                    selection: Binding(get: { type }, set: { chosenType = $0 })
                )
                AdminTextField(
                    label: i18n.resolve("admin.agents.create.fields.description"),
                    name: "description",
                    text: $agentDescription
                )
                AdminFormActions(
                    i18n: i18n,
                    submitLabel: i18n.resolve("admin.agents.create.submit"),
                    isSubmitting: isSubmitting,
                    canSubmit: !trimmedName.isEmpty && !type.isEmpty,
                    onCancel: onCancel
                ) {
                    let text = agentDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSubmit(
                        AgentCreateSubmission(name: trimmedName, type: type, description: text.isEmpty ? nil : text)
                    )
                }
            }
        }
    }
}

/// Registers an agent through the management API, in `ouId` or the signed-in user's own
/// organization unit when it is not given.
public struct AgentCreate: View {
    @EnvironmentObject private var thunderState: ThunderIDState
    let ouId: String?
    let owner: String?
    let title: String?
    let description: String?
    let onCancel: (() -> Void)?
    let onCreated: ((Agent) -> Void)?

    public init(
        ouId: String? = nil,
        owner: String? = nil,
        title: String? = nil,
        description: String? = nil,
        onCancel: (() -> Void)? = nil,
        onCreated: ((Agent) -> Void)? = nil
    ) {
        self.ouId = ouId
        self.owner = owner
        self.title = title
        self.description = description
        self.onCancel = onCancel
        self.onCreated = onCreated
    }

    public var body: some View {
        let state = thunderState
        AdminQueryReader(state.agentTypesQuery(limit: 100)) { types in
            AdminCreateHost(state: state, ouId: ouId, mutation: state.createAgentMutation()) { host in
                BaseAgentCreate(
                    agentTypes: (types.data?.types ?? []).map { AdminOption(label: $0.displayName, value: $0.handle) },
                    error: host.errorMessage(fallbackKey: "admin.agents.create.error"),
                    isSubmitting: host.isSubmitting,
                    title: title,
                    description: description,
                    onCancel: onCancel
                ) { submission in
                    host.submit { ouId in
                        var request = CreateAgentRequest(ouId: ouId, type: submission.type, name: submission.name)
                        request.description = submission.description
                        request.owner = owner
                        return request
                    } onCreated: { onCreated?($0) }
                }
            }
        }
    }
}
