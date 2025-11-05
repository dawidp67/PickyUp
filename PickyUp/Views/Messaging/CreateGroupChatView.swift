//
// CreateGroupChatView.swift
//
// Views/Messaging/CreateGroupChatView.swift
//
// Last Updated 11/4/25

import SwiftUI

struct CreateGroupChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    
    @State private var groupName = ""
    @State private var selectedUsers: Set<String> = []
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Group Name") {
                    TextField("Enter group name", text: $groupName)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Select Members") {
                    if friendshipViewModel.friends.isEmpty {
                        Text("You need friends to create a group chat")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(friendshipViewModel.friends) { friendship in
                            if let currentUserId = authViewModel.currentUser?.id {
                                let friendId = friendship.otherUserId(currentUserId: currentUserId)
                                if let friend = friendshipViewModel.friendUsers[friendId] {
                                    FriendSelectionRow(
                                        user: friend,
                                        isSelected: selectedUsers.contains(friendId)
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        toggleSelection(userId: friendId)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if !selectedUsers.isEmpty {
                    Section {
                        Text("Selected: \(selectedUsers.count) member\(selectedUsers.count == 1 ? "" : "s")")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
            .disabled(isCreating)
        }
    }
    
    private var isFormValid: Bool {
        !groupName.trimmingCharacters(in: .whitespaces).isEmpty && selectedUsers.count >= 2
    }
    
    private func toggleSelection(userId: String) {
        if selectedUsers.contains(userId) {
            selectedUsers.remove(userId)
        } else {
            selectedUsers.insert(userId)
        }
    }
    
    private func createGroup() {
        guard let currentUserId = authViewModel.currentUser?.id,
              let currentUserName = authViewModel.currentUser?.displayName else { return }
        
        isCreating = true
        
        // Get selected users
        var participants: [User] = []
        for userId in selectedUsers {
            if let user = friendshipViewModel.friendUsers[userId] {
                participants.append(user)
            }
        }
        
        Task {
            await messagingViewModel.createGroupChat(
                name: groupName,
                participants: participants,
                currentUserId: currentUserId,
                currentUserName: currentUserName
            )
            
            isCreating = false
            
            if messagingViewModel.errorMessage == nil {
                dismiss()
            }
        }
    }
}

// MARK: - Friend Selection Row
struct FriendSelectionRow: View {
    let user: User
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(user.initials)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            
            Text(user.displayName)
                .font(.headline)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}
