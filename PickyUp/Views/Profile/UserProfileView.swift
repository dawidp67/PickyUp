//
// UserProfileView.swift
//
// Views/Profile/UserProfileView.swift
//
// Last Updated 11/4/25

import SwiftUI

struct UserProfileView: View {
    let user: User
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var friendshipStatus: Friendship?
    @State private var isLoading = false
    @State private var showingUserSettings = false
    @State private var showingMoreOptions = false
    @State private var showBlockConfirmation = false
    @State private var statusMessage: String?
    @State private var showingConversation = false
    @State private var conversationId: String?
    
    var currentUserId: String {
        authViewModel.currentUser?.id ?? ""
    }
    
    var isBlocked: Bool {
        friendshipStatus?.status == .blocked
    }
    
    var isFriend: Bool {
        friendshipStatus?.status == .accepted
    }
    
    var isPending: Bool {
        friendshipStatus?.status == .pending
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.gradient)
                                .frame(width: 100, height: 100)
                            
                            Text(user.initials)
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        
                        Text(user.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    // Action Buttons
                    if !isBlocked {
                        HStack(spacing: 16) {
                            // Add Friend / Already Friends Button
                            if !isFriend && !isPending {
                                Button {
                                    Task { await sendFriendRequest() }
                                } label: {
                                    Label("Add Friend", systemImage: "person.badge.plus")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundStyle(.white)
                                        .cornerRadius(10)
                                }
                                .disabled(isLoading)
                            } else if isPending {
                                Button {} label: {
                                    Label("Pending", systemImage: "clock")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.gray)
                                        .foregroundStyle(.white)
                                        .cornerRadius(10)
                                }
                                .disabled(true)
                            }
                            
                            // Message Button
                            Button {
                                Task { await openConversation() }
                            } label: {
                                Label("Message", systemImage: "message")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(isLoading)
                        }
                        .padding(.horizontal)
                    } else {
                        Text("This user is blocked")
                            .foregroundStyle(.red)
                            .padding()
                    }
                    
                    // Status Message
                    if let message = statusMessage {
                        Text(message)
                            .font(.caption)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingMoreOptions = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingUserSettings) {
                UserSettingsSheet(targetUser: user, friendship: friendshipStatus)
                    .environmentObject(authViewModel)
            }
            .confirmationDialog("More Options", isPresented: $showingMoreOptions, titleVisibility: .hidden) {
                if isFriend {
                    Button("User Settings") {
                        showingUserSettings = true
                    }
                }
                
                Button(isBlocked ? "Unblock" : "Block", role: .destructive) {
                    if !isBlocked {
                        showBlockConfirmation = true
                    } else {
                        Task { await unblockUser() }
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .alert("Block User?", isPresented: $showBlockConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Block", role: .destructive) {
                    Task { await blockUser() }
                }
            } message: {
                Text("You won't see each other's games, and you won't be able to search or message each other.")
            }
            .sheet(isPresented: $showingConversation) {
                if let convId = conversationId {
                    ChatView(conversationId: convId)
                        .environmentObject(messagingViewModel)
                        .environmentObject(authViewModel)
                }
            }
            .task {
                await fetchFriendshipStatus()
            }
        }
    }
    
    // MARK: - Actions
    
    func fetchFriendshipStatus() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        do {
            friendshipStatus = try await FriendshipService.shared.getFriendshipStatus(userId1: userId, userId2: user.id ?? "")
        } catch {
            print("Error fetching friendship status: \(error)")
        }
    }
    
    func sendFriendRequest() async {
        guard let userId = authViewModel.currentUser?.id,
              let targetId = user.id else { return }
        
        isLoading = true
        do {
            _ = try await FriendshipService.shared.sendFriendRequest(from: userId, to: targetId)
            await fetchFriendshipStatus()
            showStatus("Friend request sent!")
        } catch {
            showStatus(error.localizedDescription)
        }
        isLoading = false
    }
    
    func blockUser() async {
        guard let userId = authViewModel.currentUser?.id,
              let targetId = user.id else { return }
        
        isLoading = true
        do {
            try await FriendshipService.shared.blockUser(currentUserId: userId, targetUserId: targetId)
            await fetchFriendshipStatus()
            showStatus("\(user.displayName) blocked!")
        } catch {
            showStatus("Error blocking user")
        }
        isLoading = false
    }
    
    func unblockUser() async {
        guard let friendshipId = friendshipStatus?.id else { return }
        
        isLoading = true
        do {
            try await FriendshipService.shared.unblockUser(friendshipId: friendshipId)
            await fetchFriendshipStatus()
            showStatus("\(user.displayName) unblocked")
        } catch {
            showStatus("Error unblocking user")
        }
        isLoading = false
    }
    
    func openConversation() async {
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
            conversationId = convId
            showingConversation = true
        } catch {
            if isBlocked {
                showStatus("Unexpected error")
            } else {
                showStatus("Error opening conversation")
            }
        }
        isLoading = false
    }
    
    func showStatus(_ message: String) {
        statusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            statusMessage = nil
        }
    }
}
