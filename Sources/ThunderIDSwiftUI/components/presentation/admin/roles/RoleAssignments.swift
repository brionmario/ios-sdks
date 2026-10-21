// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ThunderID

/// The identities a role is assigned to, rendered from the data it is given. Assigning is offered
/// when both `onAssign` and `candidates` are set, for each assignee type `candidates` has an entry
/// for; unassigning when `onUnassign` is set.
public struct BaseRoleAssignments: View {
    @EnvironmentObject private var i18n: ThunderIDI18n
    let assignments: [RoleAssignment]
    let candidates: [RoleAssigneeType: [IdentityCandidate]]?
    let isLoading: Bool
    let error: String?
    let isMutating: Bool
    let title: String?
    let description: String?
    let onAssign: ((RoleAssignmentInput) -> Void)?
    let onUnassign: ((RoleAssignment) -> Void)?

    public init(
        assignments: [RoleAssignment],
        candidates: [RoleAssigneeType: [IdentityCandidate]]? = nil,
        isLoading: Bool = false,
        error: String? = nil,
        isMutating: Bool = false,
        title: String? = nil,
        description: String? = nil,
        onAssign: ((RoleAssignmentInput) -> Void)? = nil,
        onUnassign: ((RoleAssignment) -> Void)? = nil
    ) {
        self.assignments = assignments
        self.candidates = candidates
        self.isLoading = isLoading
        self.error = error
        self.isMutating = isMutating
        self.title = title
        self.description = description
        self.onAssign = onAssign
        self.onUnassign = onUnassign
    }

    public var body: some View {
        AdminIdentityTable(
            i18n: i18n,
            identifier: "admin-role-assignments",
            title: title ?? i18n.resolve("admin.roles.assignments.title"),
            description: description,
            rows: assignments.map { AdminRelatedIdentity(id: $0.id, type: $0.type, display: $0.display) },
            emptyText: i18n.resolve("admin.roles.assignments.empty"),
            addLabel: i18n.resolve("admin.roles.assignments.add"),
            removeLabelKey: "admin.roles.assignments.remove_label",
            typeOrder: [.user, .group, .agent, .app],
            candidates: candidates,
            isLoading: isLoading,
            error: error,
            isMutating: isMutating,
            onAdd: onAssign.map { assign in { id, type in assign(RoleAssignmentInput(id: id, type: type)) } },
            onRemove: onUnassign.map { unassign in
                { identity in
                    unassign(RoleAssignment(id: identity.id, type: identity.type, display: identity.display))
                }
            }
        )
    }
}

/// The identities a role is assigned to, loaded through the management API. Set `editable` to let
/// the signed-in user assign the role to users, groups and agents and remove assignments; it is
/// off by default.
public struct RoleAssignments: View {
    @EnvironmentObject private var thunderState: ThunderIDState
    let roleId: String
    let editable: Bool
    let title: String?
    let description: String?

    public init(roleId: String, editable: Bool = false, title: String? = nil, description: String? = nil) {
        self.roleId = roleId
        self.editable = editable
        self.title = title
        self.description = description
    }

    public var body: some View {
        RoleAssignmentsHost(state: thunderState, props: self).id("\(roleId)|\(editable)")
    }
}

private struct RoleAssignmentsHost: View {
    @EnvironmentObject private var i18n: ThunderIDI18n
    @StateObject private var assignments: ResourceQuery<RoleAssignmentListResponse>
    @StateObject private var users: ResourceQuery<ManagedUserListResponse>
    @StateObject private var groups: ResourceQuery<GroupListResponse>
    @StateObject private var agents: ResourceQuery<AgentListResponse>
    @StateObject private var assign: ResourceMutation<RoleAssignmentsInput, Void>
    @StateObject private var unassign: ResourceMutation<RoleAssignmentsInput, Void>
    let props: RoleAssignments

    init(state: ThunderIDState, props: RoleAssignments) {
        _assignments = StateObject(wrappedValue: state.roleAssignmentsQuery(roleId: props.roleId, limit: 100))
        _users = StateObject(wrappedValue: state.usersQuery(limit: 100))
        _groups = StateObject(wrappedValue: state.groupsQuery(limit: 100))
        _agents = StateObject(wrappedValue: state.agentsQuery(limit: 100))
        _assign = StateObject(wrappedValue: state.addRoleAssignmentsMutation())
        _unassign = StateObject(wrappedValue: state.removeRoleAssignmentsMutation())
        self.props = props
    }

    var body: some View {
        BaseRoleAssignments(
            assignments: assignments.data?.assignments ?? [],
            candidates: props.editable ? candidates : nil,
            isLoading: assignments.isLoading,
            error: i18n.managementErrorMessage(assignments.error, fallbackKey: "admin.roles.assignments.error")
                ?? i18n.managementErrorMessage(
                    assign.error ?? unassign.error,
                    fallbackKey: "admin.roles.assignments.update_error"
                ),
            isMutating: assign.isLoading || unassign.isLoading,
            title: props.title,
            description: props.description,
            onAssign: props.editable ? addAssignment : nil,
            onUnassign: props.editable ? removeAssignment : nil
        )
        .task {
            await assignments.refetch()
            guard props.editable else { return }
            await users.refetch()
            await groups.refetch()
            await agents.refetch()
        }
    }

    private var candidates: [RoleAssigneeType: [IdentityCandidate]] {
        [
            .user: AdminCandidates.users(users.data),
            .group: AdminCandidates.groups(groups.data),
            .agent: AdminCandidates.agents(agents.data)
        ]
    }

    private func addAssignment(_ assignment: RoleAssignmentInput) {
        Task { await assign.mutate((roleId: props.roleId, assignments: [assignment])) }
    }

    private func removeAssignment(_ assignment: RoleAssignment) {
        let input = RoleAssignmentInput(id: assignment.id, type: assignment.type)
        Task { await unassign.mutate((roleId: props.roleId, assignments: [input])) }
    }
}
