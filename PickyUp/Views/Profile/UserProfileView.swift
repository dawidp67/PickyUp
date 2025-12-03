//
// UserProfileView.swift
//
// Views/Profile/UserProfileView.swift
//
// Last Updated 11/19/25

import SwiftUI

struct UserProfileView: View {
    let user: AppUser
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var friendshipStatus: Friendship?
    @State private var isLoading = false
    @State private var showingUserSettings = false
    @State private var showingMoreOptions = false
    @State private var showBlockConfirmation = false
    @State private var showUnfriendConfirmation = false
    @State private var statusMessage: String?
    @State private var showingConversation = false
    @State private var conversationId: String?
    @State private var userGames: [Game] = []
    @State private var isLoadingGames = true
    
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
    
    var isPendingOutgoing: Bool {
        guard let friendship = friendshipStatus, friendship.status == .pending else { return false }
        return friendship.requesterId == currentUserId
    }
    
    var isPendingIncoming: Bool {
        guard let friendship = friendshipStatus, friendship.status == .pending else { return false }
        return friendship.requesterId != currentUserId
    }
    
    var body: some View {
        NavigationStack {
            UserProfileContentView(
                user: user,
                friendshipStatus: friendshipStatus,
                isBlocked: isBlocked,
                isFriend: isFriend,
                isPendingOutgoing: isPendingOutgoing,
                isPendingIncoming: isPendingIncoming,
                isLoading: isLoading,
                statusMessage: statusMessage,
                userGames: userGames,
                isLoadingGames: isLoadingGames,
                showingUserSettings: $showingUserSettings,
                showingMoreOptions: $showingMoreOptions,
                showBlockConfirmation: $showBlockConfirmation,
                showUnfriendConfirmation: $showUnfriendConfirmation,
                showingConversation: $showingConversation,
                conversationId: conversationId,
                parentView: self
            )
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
                
                if isFriend {
                    Button("Unfriend", role: .destructive) {
                        showUnfriendConfirmation = true
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
            .alert("Unfriend User?", isPresented: $showUnfriendConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Unfriend", role: .destructive) {
                    Task { await unfriendUser() }
                }
            } message: {
                Text("You will no longer be friends with \(user.displayName).")
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
                await fetchUserGames()
            }
            .onChange(of: friendshipViewModel.friends) { _, _ in
                Task { await fetchFriendshipStatus() }
            }
            .onChange(of: friendshipViewModel.pendingRequests) { _, _ in
                Task { await fetchFriendshipStatus() }
            }
        }
    }
    
    // MARK: - Actions
    func blockUser() async {
        guard let targetId = user.id, !currentUserId.isEmpty else { return }
        isLoading = true
        do {
            try await FriendshipService.shared.blockUser(currentUserId: currentUserId, targetUserId: targetId)
            statusMessage = "User blocked."
            await fetchFriendshipStatus()
        } catch {
            statusMessage = "Failed to block: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func unblockUser() async {
        guard let targetId = user.id, !currentUserId.isEmpty else { return }
        let friendshipId = Friendship.generateId(userId1: currentUserId, userId2: targetId)
        isLoading = true
        do {
            try await FriendshipService.shared.unblockUser(friendshipId: friendshipId, userId: currentUserId)
            statusMessage = "User unblocked."
            await fetchFriendshipStatus()
        } catch {
            statusMessage = "Failed to unblock: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func unfriendUser() async {
        guard let targetId = user.id, !currentUserId.isEmpty else { return }
        let friendshipId = Friendship.generateId(userId1: currentUserId, userId2: targetId)
        isLoading = true
        do {
            try await FriendshipService.shared.removeFriend(friendshipId: friendshipId, userId: currentUserId)
            statusMessage = "Removed from friends."
            await fetchFriendshipStatus()
        } catch {
            statusMessage = "Failed to remove friend: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func fetchFriendshipStatus() async {
        guard let targetId = user.id, !currentUserId.isEmpty else { return }
        isLoading = true
        do {
            let status = try await FriendshipService.shared.getFriendshipStatus(userId1: currentUserId, userId2: targetId)
            await MainActor.run {
                friendshipStatus = status
            }
        } catch {
            await MainActor.run {
                statusMessage = "Failed to load friendship: \(error.localizedDescription)"
            }
        }
        isLoading = false
    }
    
    func fetchUserGames() async {
        await MainActor.run {
            userGames = []
            isLoadingGames = false
        }
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    let user: AppUser
    let isBlocked: Bool
    let isFriend: Bool
    let isPendingOutgoing: Bool
    let isPendingIncoming: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if let urlString = user.profilePhotoURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 100)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        case .failure:
                            initialsCircle
                        @unknown default:
                            initialsCircle
                        }
                    }
                } else {
                    initialsCircle
                }
            }
            
            Text(user.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(user.email)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            FriendshipStatusPill(
                isBlocked: isBlocked,
                isFriend: isFriend,
                isPendingOutgoing: isPendingOutgoing,
                isPendingIncoming: isPendingIncoming
            )
        }
        .padding(.top)
    }
    
    private var initialsCircle: some View {
        ZStack {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 100, height: 100)
            
            Text(user.initials)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

struct FriendshipStatusPill: View {
    let isBlocked: Bool
    let isFriend: Bool
    let isPendingOutgoing: Bool
    let isPendingIncoming: Bool
    
    var body: some View {
        Group {
            if isBlocked {
                Text("Blocked")
                    .padding(6)
                    .background(Color.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            } else if isFriend {
                Text("Friends")
                    .padding(6)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            } else if isPendingOutgoing {
                Text("Request Sent")
                    .padding(6)
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            } else if isPendingIncoming {
                Text("Request Received")
                    .padding(6)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            } else {
                EmptyView()
            }
        }
    }
}

struct UserProfileContentView: View {
    let user: AppUser
    let friendshipStatus: Friendship?
    let isBlocked: Bool
    let isFriend: Bool
    let isPendingOutgoing: Bool
    let isPendingIncoming: Bool
    let isLoading: Bool
    let statusMessage: String?
    let userGames: [Game]
    let isLoadingGames: Bool
    
    @Binding var showingUserSettings: Bool
    @Binding var showingMoreOptions: Bool
    @Binding var showBlockConfirmation: Bool
    @Binding var showUnfriendConfirmation: Bool
    @Binding var showingConversation: Bool
    let conversationId: String?
    
    let parentView: UserProfileView
    
    var body: some View {
        List {
            Section {
                ProfileHeaderView(
                    user: user,
                    isBlocked: isBlocked,
                    isFriend: isFriend,
                    isPendingOutgoing: isPendingOutgoing,
                    isPendingIncoming: isPendingIncoming
                )
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
            }
            
            if let msg = statusMessage {
                Section {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Actions") {
                if !isBlocked {
                    if isFriend {
                        Button {
                            showingMoreOptions = true
                        } label: {
                            Label("More Options", systemImage: "ellipsis.circle")
                        }
                    } else if isPendingIncoming {
                        HStack {
                            Text("Friend request pending")
                            Spacer()
                        }
                    } else if isPendingOutgoing {
                        HStack {
                            Text("Friend request sent")
                            Spacer()
                        }
                    } else {
                        Button {
                            showingMoreOptions = true
                        } label: {
                            Label("Options", systemImage: "ellipsis.circle")
                        }
                    }
                } else {
                    Button(role: .destructive) {
                        Task { await parentView.unblockUser() }
                    } label: {
                        Label("Unblock", systemImage: "hand.raised.slash")
                    }
                }
            }
            
            Section("Games") {
                if isLoadingGames {
                    ProgressView()
                } else if userGames.isEmpty {
                    Text("No games to show")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(userGames) { game in
                        VStack(alignment: .leading) {
                            Text(game.displaySportName)
                                .font(.headline)
                            Text(game.location.address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(user.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingMoreOptions = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
