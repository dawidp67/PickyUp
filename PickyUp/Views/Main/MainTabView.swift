//
// MainTabView.swift
//
// Views/Main/MainTabView.swift
//
// Last Updated 11/4/25

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var gameViewModel: GameViewModel
    @StateObject private var messagingViewModel = MessagingViewModel()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @StateObject private var friendshipViewModel = FriendshipViewModel()
    
    var body: some View {
        TabView {
            GameListView()
                .tabItem {
                    Label("Games", systemImage: "sportscourt")
                }
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            MessagingView()
                .tabItem {
                    Label("Messages", systemImage: "message")
                }
                .badge(messagingViewModel.conversations.filter { hasUnreadMessages($0) }.count > 0 ? messagingViewModel.conversations.filter { hasUnreadMessages($0) }.count : 0)
                .environmentObject(messagingViewModel)
                .environmentObject(friendshipViewModel)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .badge(notificationViewModel.unreadCount > 0 ? notificationViewModel.unreadCount : 0)
                .environmentObject(notificationViewModel)
                .environmentObject(friendshipViewModel)
        }
        .accentColor(.blue)
        .onAppear {
            setupViewModels()
        }
    }
    
    private func setupViewModels() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        // Setup real-time listeners
        messagingViewModel.setupConversationsListener(userId: userId)
        notificationViewModel.setupNotificationsListener(userId: userId)
        friendshipViewModel.setupFriendsListener(userId: userId)
        
        // Fetch initial data
        Task {
            await friendshipViewModel.fetchPendingRequests(userId: userId)
        }
    }
    
    private func hasUnreadMessages(_ conversation: Conversation) -> Bool {
        // Simplified - in production, track read status properly
        return false
    }
}
