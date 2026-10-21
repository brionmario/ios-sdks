// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ThunderID

/// A page of agents, rendered from the data it is given. Pair it with
/// ``ThunderIDState/agentsQuery(limit:offset:fetcher:)`` or any other source; ``AgentList`` does that for you.
public struct BaseAgentList: View {
    @EnvironmentObject private var i18n: ThunderIDI18n
    let agents: [BasicAgent]
    let isLoading: Bool
    let error: String?
    let title: String?
    let description: String?
    let limit: Int
    let offset: Int
    let totalResults: Int?
    let selectedAgentId: String?
    let onPageChange: ((Int) -> Void)?
    let onSelect: ((BasicAgent) -> Void)?
    let actions: AnyView?

    public init(
        agents: [BasicAgent],
        isLoading: Bool = false,
        error: String? = nil,
        title: String? = nil,
        description: String? = nil,
        limit: Int = 20,
        offset: Int = 0,
        totalResults: Int? = nil,
        selectedAgentId: String? = nil,
        onPageChange: ((Int) -> Void)? = nil,
        onSelect: ((BasicAgent) -> Void)? = nil,
        actions: AnyView? = nil
    ) {
        self.agents = agents
        self.isLoading = isLoading
        self.error = error
        self.title = title
        self.description = description
        self.limit = limit
        self.offset = offset
        self.totalResults = totalResults
        self.selectedAgentId = selectedAgentId
        self.onPageChange = onPageChange
        self.onSelect = onSelect
        self.actions = actions
    }

    public var body: some View {
        AdminSection(
            identifier: "admin-agent-list",
            title: title ?? i18n.resolve("admin.agents.list.title"),
            description: description,
            actions: { actions },
            content: {
                AdminTable(
                    identifier: "admin-agent-list",
                    rows: agents,
                    rowId: \.id,
                    isLoading: isLoading,
                    error: error,
                    emptyText: i18n.resolve("admin.agents.list.empty"),
                    selectedId: selectedAgentId,
                    onSelect: onSelect,
                    pagination: onPageChange.map {
                        AdminPagination(
                            i18n: i18n,
                            limit: limit,
                            offset: offset,
                            total: totalResults ?? agents.count,
                            onChange: $0
                        )
                    },
                    row: { agent in
                        AdminRowLabel(
                            title: agent.name,
                            details: [agent.type, agent.clientId ?? "", agent.ouHandle ?? agent.ouId]
                        )
                    },
                    i18n: i18n
                )
            }
        )
    }
}

/// A paginated list of the agents the signed-in user can see. Selecting a row calls `onSelect`;
/// the application decides where that leads.
public struct AgentList: View {
    @EnvironmentObject private var thunderState: ThunderIDState
    @EnvironmentObject private var i18n: ThunderIDI18n
    let limit: Int
    let title: String?
    let description: String?
    let selectedAgentId: String?
    let onSelect: ((BasicAgent) -> Void)?
    let actions: AnyView?
    @State private var offset = 0

    public init(
        limit: Int = 20,
        title: String? = nil,
        description: String? = nil,
        selectedAgentId: String? = nil,
        onSelect: ((BasicAgent) -> Void)? = nil,
        actions: AnyView? = nil
    ) {
        self.limit = limit
        self.title = title
        self.description = description
        self.selectedAgentId = selectedAgentId
        self.onSelect = onSelect
        self.actions = actions
    }

    public var body: some View {
        let state = thunderState
        AdminQueryReader(state.agentsQuery(limit: limit, offset: offset)) { query in
            BaseAgentList(
                agents: query.data?.agents ?? [],
                isLoading: query.isLoading,
                error: i18n.managementErrorMessage(query.error, fallbackKey: "admin.agents.list.error"),
                title: title,
                description: description,
                limit: limit,
                offset: offset,
                totalResults: query.data?.totalResults,
                selectedAgentId: selectedAgentId,
                onPageChange: { offset = $0 },
                onSelect: onSelect,
                actions: actions
            )
        }
        .id("\(offset)|\(limit)")
    }
}
