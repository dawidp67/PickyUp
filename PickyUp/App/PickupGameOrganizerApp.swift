//
//  PickupGameOrganizerApp.swift
//
//  Last Updated 11/5/25

import SwiftUI
import FirebaseCore

@main
struct PickupGameOrganizerApp: App {
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var messagingViewModel = MessagingViewModel()
    @StateObject private var friendshipViewModel = FriendshipViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    
    init() {
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(gameViewModel)
                .environmentObject(messagingViewModel)
                .environmentObject(friendshipViewModel)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .tint(themeManager.currentAccentColor.color)
                .dynamicTypeSize(themeManager.useDynamicType ? .medium ... .accessibility5 : .medium ... .medium)
        }
    }
}
