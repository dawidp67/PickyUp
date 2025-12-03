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
                                
                                // Create a temporary User placeholder
                                let user = User(
                                    id: friendId,
                                    email: "",               // required first
                                    displayName: friendId,   // comes after email
                                    createdAt: Date()
                                )
                                
                                FriendSelectionRow(
                                    user: user,
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
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createGroup() }
                        .disabled(!isFormValid || isCreating)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    CloseToolbarButton()
                }
            }
            .disabled(isCreating)
        }
    }
    
    private var isFormValid: Bool {
        !groupName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedUsers.isEmpty
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
        
        // Build participants from selectedUsers
        let participants: [User] = selectedUsers.map { userId in
            User(
                id: userId,
                email: "",            // required first
                displayName: userId,  // after email
                createdAt: Date()
            )
        }
        
        Task {
            await messagingViewModel.createGroupChat(
                name: groupName.trimmingCharacters(in: .whitespaces),
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
    
    private var initials: String {
        String(user.displayName.prefix(2)).uppercased()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(initials)
                        .font(.subheadline)
                        .foregroundStyle(.primary) // changed from .blue to adaptive
                }
            
            Text(user.displayName)
                .font(.headline)
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .blue : .gray)
        }
        .padding(.vertical, 4)
    }
}

