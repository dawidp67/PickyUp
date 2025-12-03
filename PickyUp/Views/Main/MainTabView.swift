//
//  MainTabView.swift
//  PickyUp
//
//  Created by Dawid Pankiewicz on 11/10/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var messagingViewModel = MessagingViewModel()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @StateObject private var friendshipViewModel = FriendshipViewModel()
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // MARK: - Games Tab
            GameListView()
                .tabItem {
                    Label("Games", systemImage: "sportscourt.fill")
                }
                .tag(0)
            
            // MARK: - Map Tab
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(1)
            
            // MARK: - Messages Tab
            MessagingView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
                .tag(2)
            
            // MARK: - Profile Tab
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(3)
        }
        // MARK: - Shared Environment Objects
        .environmentObject(authViewModel)
        .environmentObject(gameViewModel)
        .environmentObject(messagingViewModel)
        .environmentObject(notificationViewModel)
        .environmentObject(friendshipViewModel)
        
        // MARK: - Lifecycle
        .onAppear {
            setupListeners()
        }
        .onDisappear {
            friendshipViewModel.removeListeners()
        }
    }
    
    // MARK: - Setup Listeners
    private func setupListeners() {
        guard let userId = authViewModel.currentUser?.id else { return }
        print("🚀 Setting up listeners for user: \(userId)")
        
        notificationViewModel.setupNotificationsListener(userId: userId)
        if let userId = authViewModel.currentUser?.id {
            friendshipViewModel.startListening(userId: userId)
        }

        messagingViewModel.setupConversationsListener(userId: userId)
        
        print("✅ All listeners setup complete")
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
