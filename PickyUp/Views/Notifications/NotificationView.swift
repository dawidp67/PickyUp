//
// NotificationView.swift
//
// Views/Notifications/NotificationView.swift
//
// Last Updated 11/4/25

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
                    Button("Done") {
                        dismiss()
                    }
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
                                deleteAllNotifications()
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }
    
    private var notificationsList: some View {
        List {
            ForEach(notificationViewModel.notifications) { notification in
                NotificationRowView(notification: notification)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteNotification(notification)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowBackground(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
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
    
    private func deleteNotification(_ notification: AppNotification) {
        Task {
            await notificationViewModel.deleteNotification(notification: notification)
        }
    }
    
    private func deleteAllNotifications() {
        guard let userId = authViewModel.currentUser?.id else { return }
        Task {
            await notificationViewModel.deleteAllNotifications(userId: userId)
        }
    }
}

// MARK: - Notification Row
struct NotificationRowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    
    let notification: AppNotification
    
    var body: some View {
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
                
                Text(formatTimestamp(notification.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Action Buttons for Friend Requests
                if notification.type == .friendRequest && !notification.actionTaken {
                    HStack(spacing: 12) {
                        Button {
                            acceptFriendRequest()
                        } label: {
                            Text("Accept")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        
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
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            if !notification.isRead {
                Task {
                    await notificationViewModel.markAsRead(notification: notification)
                }
            }
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
              let friendshipId = notification.friendshipId else { return }
        
        // Need to get the friendship object
        Task {
            if let friendship = await friendshipViewModel.getFriendshipStatus(userId1: currentUserId, userId2: notification.fromUserId ?? "") {
                await friendshipViewModel.acceptFriendRequest(friendship: friendship, currentUserId: currentUserId)
                await notificationViewModel.markActionTaken(notification: notification)
            }
        }
    }
    
    private func rejectFriendRequest() {
        guard let friendshipId = notification.friendshipId,
              let currentUserId = authViewModel.currentUser?.id else { return }
        
        Task {
            if let friendship = await friendshipViewModel.getFriendshipStatus(userId1: currentUserId, userId2: notification.fromUserId ?? "") {
                await friendshipViewModel.rejectFriendRequest(friendship: friendship)
                await notificationViewModel.markActionTaken(notification: notification)
            }
        }
    }
}
