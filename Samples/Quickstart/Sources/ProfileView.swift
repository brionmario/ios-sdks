// Copyright 2026 The ThunderID Authors
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ThunderIDSwiftUI

// MARK: - Profile Screen

struct ProfileScreen: View {
    let isDark: Bool
    let bgColor: Color
    let textColor: Color
    let mutedColor: Color
    let borderColor: Color
    let cardColor: Color
    let primaryBlue: Color
    let onBack: () -> Void

    var body: some View {
        // BaseUserProfile drives the /users/me data and edit/save state, so this
        // screen keeps its own card design and adds inline per-field edit controls to it.
        BaseUserProfile { profileState in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Back nav
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Home")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(primaryBlue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Text("Profile")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(textColor)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    if profileState.isLoading && profileState.profile == nil {
                        Text("Loading profile…")
                            .font(.system(size: 13))
                            .foregroundColor(mutedColor)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    } else if let error = profileState.error {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    } else {
                        identitySection(profileState)

                        sectionHeader("ACCOUNT DETAILS")
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)

                        detailsCard(profileState)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .background(bgColor)
        }
    }

    private func identitySection(_ profileState: UserProfileState) -> some View {
        VStack(spacing: 12) {
            UserAvatar(size: 56)

            VStack(spacing: 4) {
                Text(profileState.displayName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(textColor)
                if let email = profileState.email {
                    Text(email)
                        .font(.system(size: 14))
                        .foregroundColor(mutedColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.2)
            .foregroundColor(mutedColor)
    }

    private func detailsCard(_ profileState: UserProfileState) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(profileState.fields.enumerated()), id: \.element.id) { index, field in
                if index > 0 { rowDivider }
                DetailFieldRow(
                    field: field,
                    profileState: profileState,
                    textColor: textColor,
                    mutedColor: mutedColor,
                    primaryBlue: primaryBlue
                )
            }
        }
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1))
    }

    private var rowDivider: some View {
        Divider()
            .background(borderColor)
            .padding(.leading, 16)
    }
}

/// A single row: pencil to edit, then an inline field with save/cancel.
private struct DetailFieldRow: View {
    let field: ProfileField
    @ObservedObject var profileState: UserProfileState
    let textColor: Color
    let mutedColor: Color
    let primaryBlue: Color

    private var label: String { field.schema.displayName ?? field.schema.description ?? field.name }
    private var isEditing: Bool { profileState.isEditing(field.name) }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(textColor)
                Spacer()
                if isEditing && !field.isReadonly {
                    HStack(spacing: 10) {
                        TextField("", text: Binding(
                            get: { profileState.fieldValue(field) },
                            set: { profileState.setFieldValue(field.name, $0) }
                        ))
                        .font(.system(size: 13))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 140)
                        Button {
                            profileState.save(field.name)
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        Button {
                            profileState.cancel(field.name)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(mutedColor)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        let text = stringifyFieldValue(field.rawValue)
                        Text(text.isEmpty ? "-" : text)
                            .font(.system(size: 13))
                            .foregroundColor(mutedColor)
                            .multilineTextAlignment(.trailing)
                        if !field.isReadonly {
                            Button {
                                profileState.edit(field.name)
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(primaryBlue)
                            }
                        }
                    }
                }
            }
            if let error = profileState.fieldError(field.name) {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
