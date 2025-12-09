//
//  PickupGameOrganizerApp.swift
//
//  Last Updated 11/5/25

import SwiftUI
import FirebaseCore

@main
struct PickupGameOrganizerApp: App {
    // Wire AppDelegate for universal link handling and other app lifecycle services
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var messagingViewModel = MessagingViewModel()
    @StateObject private var friendshipViewModel = FriendshipViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    
    // Router state for password reset link
    @State private var pendingResetURL: URL?
    
    init() {
        // Do not configure Firebase here; AppDelegate handles it to avoid double configuration.
        print("🔥 App initialized")
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
                // Listen for AppDelegate broadcast (universal link or custom scheme)
                .onReceive(NotificationCenter.default.publisher(for: .didReceivePasswordResetLink)) { notif in
                    guard let url = notif.object as? URL else { return }
                    // Accept only resetPassword actions for safety
                    if let mode = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "mode" })?.value,
                       mode == "resetPassword" {
                        pendingResetURL = url
                    }
                }
                // Optional: also handle if SwiftUI receives URLs directly
                .onOpenURL { url in
                    if let mode = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "mode" })?.value,
                       mode == "resetPassword" {
                        pendingResetURL = url
                    }
                }
                // Present the in-app reset screen
                .sheet(item: Binding(
                    get: { pendingResetURL.map(IdentifiedURL.init(url:)) },
                    set: { item in pendingResetURL = item?.url }
                )) { item in
                    ResetPasswordActionView(actionURL: item.url)
                        .environmentObject(authViewModel)
                }
        }
    }
}

// Helper to present URL in a sheet using Identifiable
struct IdentifiedURL: Identifiable {
    let id = UUID()
    let url: URL
}
