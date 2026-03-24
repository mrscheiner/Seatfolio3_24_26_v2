// File reference refreshed to force Xcode to re-index and use this file.
import SwiftUI

struct SeasonPassSelectorView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var showAddPass = false
    @State private var showDeleteAlert = false
    @State private var deletePassId: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Choose Your League")
                    .font(.title2.bold())
                    .padding(.top, 16)

                if store.seasonPasses.isEmpty {
                    Text("No passes yet. Add one below!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    // Centered grid of passes with larger icons and more padding
                    let columns = [GridItem(.flexible(minimum: 80, maximum: 160), spacing: 32), GridItem(.flexible(minimum: 80, maximum: 160), spacing: 32)]
                    HStack {
                        Spacer(minLength: 0)
                        LazyVGrid(columns: columns, spacing: 32) {
                            ForEach(store.seasonPasses) { pass in
                                VStack(spacing: 14) {
                                    Button(action: {
                                        store.switchToPass(pass.id)
                                        dismiss()
                                    }) {
                                        VStack(spacing: 12) {
                                            TeamLogoView(
                                                teamId: pass.teamId,
                                                leagueId: pass.leagueId,
                                                size: 76
                                            )
                                            Text(pass.displayTeamName)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            Text(pass.seasonLabel)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(20)
                                        .background(pass.id == store.activePassId ? Color.blue.opacity(0.12) : Color(.systemGroupedBackground))
                                        .cornerRadius(18)
                                        .overlay(
                                            pass.id == store.activePassId ?
                                                RoundedRectangle(cornerRadius: 18)
                                                    .stroke(Color.blue, lineWidth: 2) : nil
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    HStack(spacing: 16) {
                                        if pass.id == store.activePassId {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.blue)
                                                .font(.title3)
                                        }
                                        Button(role: .destructive) {
                                            deletePassId = pass.id
                                            showDeleteAlert = true
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.body)
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                }

                Button {
                    showAddPass = true
                } label: {
                    Label("Add New Season Pass", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .padding(.top, 8)
                }
                Spacer()
            }
            .background(Color.red.opacity(0.2)) // TEMP: Visual marker for testing
            .navigationTitle("Season Passes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddPass = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Are you sure you want to delete this Season Pass?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let id = deletePassId {
                        store.deletePass(id)
                        if store.seasonPasses.isEmpty {
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete the season pass and all its data.")
            }
            .sheet(isPresented: $showAddPass) {
                SetupView()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
