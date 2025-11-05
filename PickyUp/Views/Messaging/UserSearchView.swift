//
// UserSearchView.swift
//
// Views/Messaging/UserSearchView.swift
//
// Last Updated 11/4/25

import SwiftUI

struct UserSearchView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    
    @State private var searchText = ""
    @State private var selectedUser: User?
    @State private var friendshipStatuses: [String: Friendship?] = [:]
    @State private var searchTask: Task<Void, Never>?
    
    // Navigation state for conversations
    @State private var selectedConversationId: String?
    @State private var showingConversation = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if messagingViewModel.isLoading {
                    ProgressView("Searching...")
                        .padding()
                } else if messagingViewModel.searchResults.isEmpty && !searchText.isEmpty && searchText.count >= 2 {
                    emptyStateView
                } else if !searchText.isEmpty && searchText.count < 2 {
                    Text("Type at least 2 characters to search")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Search Users")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search by name or email")
            .onChange(of: searchText) { oldValue, newValue in
                // Cancel previous search
                searchTask?.cancel()
                
                // Debounce search - wait 0.5 seconds after user stops typing
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    
                    if !Task.isCancelled {
                        await performSearch(query: newValue)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedUser) { user in
                UserPreviewView(userId: user.id ?? "", user: user)
                    .environmentObject(authViewModel)
                    .environmentObject(friendshipViewModel)
                    .environmentObject(messagingViewModel)
            }
            .navigationDestination(isPresented: $showingConversation) {
                if let conversationId = selectedConversationId {
                    ChatView(conversationId: conversationId)
                        .environmentObject(authViewModel)
                        .environmentObject(messagingViewModel)
                        .environmentObject(friendshipViewModel)
                }
            }
        }
    }
    
    private var searchResultsList: some View {
        List(messagingViewModel.searchResults) { user in
            UserSearchRowView(
                user: user,
                friendshipStatus: friendshipStatuses[user.id ?? ""] ?? nil
            )
            .contentShape(Rectangle())
            .onTapGesture {
                selectedUser = user
            }
            .onAppear {
                loadFriendshipStatus(for: user)
            }
        }
        .listStyle(.plain)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No Users Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Try searching with a different name or email")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func performSearch(query: String) async {
        guard let currentUserId = authViewModel.currentUser?.id else { return }
        await messagingViewModel.searchUsers(query: query, currentUserId: currentUserId)
    }
    
    private func loadFriendshipStatus(for user: User) {
        guard let userId = user.id,
              let currentUserId = authViewModel.currentUser?.id else { return }
        
        // Check if we already loaded this
        guard friendshipStatuses[userId] == nil else { return }
        
        Task {
            let status = await friendshipViewModel.getFriendshipStatus(userId1: currentUserId, userId2: userId)
            await MainActor.run {
                friendshipStatuses[userId] = status
            }
        }
    }
    
    func openConversation(with user: User) async {
        guard let currentUser = authViewModel.currentUser,
              let userId = currentUser.id,
              let targetId = user.id else { return }
        
        isLoading = true
        do {
            let convId = try await MessagingService.shared.getOrCreateDirectConversation(
                userId1: userId,
                userId2: targetId,
                user1Name: currentUser.displayName,
                user2Name: user.displayName
            )
            selectedConversationId = convId
            showingConversation = true
        } catch {
            print("Error opening conversation: \(error)")
        }
        isLoading = false
    }
}

// MARK: - User Search Row
struct UserSearchRowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    
    let user: User
    let friendshipStatus: Friendship?
    
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(user.initials)
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                // Add Friend Button
                if shouldShowAddFriendButton {
                    Button {
                        addFriend()
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    .disabled(isProcessing)
                }
                
                // Message Button
                Button {
                    messageUser()
                } label: {
                    Image(systemName: "message")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .disabled(isProcessing)
            }
        }
        .padding(.vertical, 4)
        .opacity(isProcessing ? 0.6 : 1.0)
    }
    
    private var shouldShowAddFriendButton: Bool {
        guard let status = friendshipStatus else { return true }
        return status.status != .accepted
    }
    
    private func addFriend() {
        guard let currentUserId = authViewModel.currentUser?.id,
              let targetUserId = user.id else { return }
        
        isProcessing = true
        
        Task {
            await friendshipViewModel.sendFriendRequest(to: targetUserId, from: currentUserId)
            isProcessing = false
        }
    }
    
    private func messageUser() {
        guard let currentUserId = authViewModel.currentUser?.id,
              let currentUserName = authViewModel.currentUser?.displayName else { return }
        
        isProcessing = true
        
        Task {
            let _ = try? await messagingViewModel.startDMConversation(
                withUser: user,
                currentUserId: currentUserId,
                currentUserName: currentUserName
            )
            isProcessing = false
        }
    }
}
