//
// NotificationView.swift
//
// Views/Notifications/NotificationView.swift
//
// Last Updated 11/17/25

import SwiftUI

struct NotificationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if notificationViewModel.notifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseToolbarButton()
                }
                
                if !notificationViewModel.notifications.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                markAllAsRead()
                            } label: {
                                Label("Mark All as Read", systemImage: "checkmark.circle")
                            }
                            
                            Button(role: .destructive) {
                                clearAllNotifications()
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .task {
                // Setup listener for real-time notifications
                if let userId = authViewModel.currentUser?.id {
                    notificationViewModel.setupNotificationsListener(userId: userId)
                }
            }
            .onDisappear {
                // Clean up listener when view disappears
                notificationViewModel.removeListener()
            }
            .onAppear {
                // Debug logging
                print("🔔 NotificationView appeared")
                print("🔔 Current user ID: \(authViewModel.currentUser?.id ?? "nil")")
                print("🔔 Notifications count: \(notificationViewModel.notifications.count)")
            }
        }
    }
    
    private var notificationsList: some View {
        List {
            ForEach(notificationViewModel.notifications) { notification in
                NotificationRowView(notification: notification)
                    .listRowBackground(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteNotification(notification)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No Notifications")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You're all caught up!")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    private func markAllAsRead() {
        guard let userId = authViewModel.currentUser?.id else { return }
        Task {
            await notificationViewModel.markAllAsRead(userId: userId)
        }
    }
    
    private func clearAllNotifications() {
        guard let userId = authViewModel.currentUser?.id else { return }
        Task {
            do {
                try await NotificationService.shared.deleteAllNotifications(userId: userId)
            } catch {
                print("Error clearing notifications: \(error)")
            }
        }
    }
    
    private func deleteNotification(_ notification: AppNotification) {
        guard let notificationId = notification.id else { return }
        Task {
            do {
                try await NotificationService.shared.deleteNotification(notificationId: notificationId)
            } catch {
                print("Error deleting notification: \(error)")
            }
        }
    }
}

// Replace your NotificationRowView struct with this improved version

struct NotificationRowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    
    @State private var showingGameDetail = false
    @State private var showingConversation = false
    @State private var isProcessing = false
    @State private var localActionTaken = false
    
    let notification: AppNotification
    
    var body: some View {
        Button {
            handleNotificationTap()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Image(systemName: getIcon())
                    .font(.title3)
                    .foregroundStyle(getIconColor())
                    .frame(width: 40, height: 40)
                    .background(getIconColor().opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let fromUserName = notification.fromUserName {
                            Text(fromUserName)
                                .font(.headline)
                        } else {
                            Text(notification.title)
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    Text(formatTimestamp(notification.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Action Buttons for Friend Requests
                    if notification.type == .friendRequest && !notification.actionTaken && !localActionTaken {
                        HStack(spacing: 12) {
                            Button {
                                acceptFriendRequest()
                            } label: {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(width: 20, height: 20)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                } else {
                                    Text("Accept")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                }
                            }
                            .background(Color.blue)
                            .cornerRadius(8)
                            .disabled(isProcessing)
                            
                            Button {
                                rejectFriendRequest()
                            } label: {
                                Text("Decline")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .disabled(isProcessing)
                        }
                        .padding(.top, 4)
                    } else if notification.type == .friendRequest && (notification.actionTaken || localActionTaken) {
                        Text("Request handled")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingGameDetail) {
            if let gameId = notification.gameId {
                GameDetailNavigationWrapper(gameId: gameId)
            }
        }
        .sheet(isPresented: $showingConversation) {
            if let conversationId = notification.conversationId {
                ChatView(conversationId: conversationId)
                    .environmentObject(authViewModel)
            }
        }
    }
    
    private func handleNotificationTap() {
        // Mark as read
        if !notification.isRead, let notificationId = notification.id {
            Task {
                await notificationViewModel.markAsRead(notificationId: notificationId)
            }
        }
        
        // Navigate based on notification type
        switch notification.type {
        case .newMessage:
            if notification.conversationId != nil {
                showingConversation = true
            }
        case .gameUpdate, .gameReminder, .newGame:
            if notification.gameId != nil {
                showingGameDetail = true
            }
        case .friendRequest, .friendAccepted:
            // Friend requests are handled by buttons in the notification
            break
        case .blocked:
            break
        }
    }
    
    private func getIcon() -> String {
        switch notification.type {
        case .friendRequest:
            return "person.badge.plus"
        case .friendAccepted:
            return "person.2.fill"
        case .newMessage:
            return "message.fill"
        case .newGame:
            return "sportscourt.fill"
        case .gameUpdate:
            return "pencil.circle.fill"
        case .gameReminder:
            return "bell.fill"
        case .blocked:
            return "hand.raised.fill"
        }
    }
    
    private func getIconColor() -> Color {
        switch notification.type {
        case .friendRequest, .friendAccepted:
            return .blue
        case .newMessage:
            return .green
        case .newGame, .gameUpdate, .gameReminder:
            return .orange
        case .blocked:
            return .red
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let minutes = components.minute, minutes < 60 {
            if minutes == 0 {
                return "Just now"
            }
            return "\(minutes)m ago"
        } else if let hours = components.hour, hours < 24 {
            return "\(hours)h ago"
        } else if let days = components.day, days < 7 {
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func acceptFriendRequest() {
        guard let currentUserId = authViewModel.currentUser?.id,
              let friendshipId = notification.friendshipId else {
            print("❌ Missing required data for accepting friend request")
            return
        }
        
        isProcessing = true
        
        Task {
            print("✅ Accepting friend request - friendshipId: \(friendshipId)")
            
            await friendshipViewModel.acceptFriendRequest(
                friendshipId: friendshipId,
                userId: currentUserId
            )
            
            // Mark action as taken in the notification
            if let notificationId = notification.id {
                try? await NotificationService.shared.markActionTaken(notificationId: notificationId)
            }
            
            await MainActor.run {
                localActionTaken = true
                isProcessing = false
                print("✅ Friend request accepted successfully")
            }
        }
    }
    
    private func rejectFriendRequest() {
        guard let friendshipId = notification.friendshipId else {
            print("❌ Missing friendshipId for declining friend request")
            return
        }
        
        isProcessing = true
        
        Task {
            print("🚫 Declining friend request - friendshipId: \(friendshipId)")
            
            await friendshipViewModel.declineFriendRequest(friendshipId: friendshipId)
            
            // Mark action as taken in the notification
            if let notificationId = notification.id {
                try? await NotificationService.shared.markActionTaken(notificationId: notificationId)
            }
            
            await MainActor.run {
                localActionTaken = true
                isProcessing = false
                print("✅ Friend request declined successfully")
            }
        }
    }
}

// MARK: - Game Detail Navigation Wrapper
struct GameDetailNavigationWrapper: View {
    let gameId: String
    @State private var game: Game?
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let game = game {
                    GameDetailView(game: game)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)
                        Text("Game not found")
                            .font(.headline)
                        Text("This game may have been deleted")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            // Remove extra close here; GameDetailView has its own Close button.
            .task {
                await loadGame()
            }
        }
    }
    
    private func loadGame() async {
        do {
            game = try await GameService.shared.fetchGame(gameId: gameId)
        } catch {
            print("Error loading game: \(error)")
        }
        isLoading = false
    }
}

