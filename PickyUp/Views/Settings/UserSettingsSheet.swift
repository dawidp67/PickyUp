//
// UserSettingsSheet.swift
//
// Views/Settings/UserSettingsSheet.swift
//
// Last Updated 11/4/25

import SwiftUI

struct UserSettingsSheet: View {
    let targetUser: User
    let friendship: Friendship?
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var allowDirectMessages = true
    @State private var allowGroupMessages = true
    @State private var showGames = true
    @State private var canCollaborate = false
    @State private var showRemoveFriendConfirmation = false
    @State private var isLoading = false
    
    var isFriend: Bool {
        friendship?.status == .accepted
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Messages Settings
                Section("Messages") {
                    Toggle("Direct Messages", isOn: $allowDirectMessages)
                        .onChange(of: allowDirectMessages) { _, _ in
                            Task { await saveSettings() }
                        }
                    
                    Toggle("Group Chat Messages", isOn: $allowGroupMessages)
                        .onChange(of: allowGroupMessages) { _, _ in
                            Task { await saveSettings() }
                        }
                }
                
                // Games Settings
                Section("Games") {
                    Toggle("Show Games", isOn: $showGames)
                        .onChange(of: showGames) { _, _ in
                            Task { await saveSettings() }
                        }
                    
                    Toggle("Add as Collaborator", isOn: $canCollaborate)
                        .disabled(true)  // To be implemented later
                        .onChange(of: canCollaborate) { _, _ in
                            Task { await saveSettings() }
                        }
                    
                    Text("Collaborators can edit your games")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Notifications Settings
                Section("Notifications") {
                    Toggle("Notify for New Games", isOn: .constant(true))
                        .disabled(true)  // To be implemented
                    
                    Toggle("Notify for Messages", isOn: .constant(true))
                        .disabled(true)  // To be implemented
                }
                
                // Manage Friendship
                Section {
                    Button(role: .destructive) {
                        if isFriend {
                            showRemoveFriendConfirmation = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.minus")
                            Text("Remove Friend")
                        }
                        .foregroundStyle(.red)
                    }
                    .opacity(isFriend ? 1.0 : 0.5)
                    .disabled(!isFriend)
                } header: {
                    Text("Manage Friendship")
                } footer: {
                    if !isFriend {
                        Text("You must be friends to manage this relationship")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("User Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Remove Friend?", isPresented: $showRemoveFriendConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    Task { await removeFriend() }
                }
            } message: {
                Text("You will no longer see each other's games and will need to send a new friend request to reconnect.")
            }
            .task {
                await loadSettings()
            }
        }
    }
    
    func loadSettings() async {
        guard let userId = authViewModel.currentUser?.id,
              let targetId = targetUser.id else { return }
        
        // Load privacy settings from Firestore
        // This would fetch from a subcollection like users/{userId}/privacySettings/{targetId}
        // For now, using defaults
        allowDirectMessages = true
        allowGroupMessages = true
        showGames = true
        canCollaborate = false
    }
    
    func saveSettings() async {
        guard let userId = authViewModel.currentUser?.id,
              let targetId = targetUser.id else { return }
        
        let privacySettings = UserPrivacySettings(
            userId: userId,
            targetUserId: targetId,
            allowDirectMessages: allowDirectMessages,
            allowGroupMessages: allowGroupMessages,
            showGames: showGames,
            canCollaborate: canCollaborate
        )
        
        // Save to Firestore - implement in UserService
        // try? await UserService.shared.updatePrivacySettings(privacySettings)
    }
    
    func removeFriend() async {
        guard let friendshipId = friendship?.id else { return }
        
        isLoading = true
        do {
            try await FriendshipService.shared.removeFriend(friendshipId: friendshipId)
            dismiss()
        } catch {
            print("Error removing friend: \(error)")
        }
        isLoading = false
    }
}
