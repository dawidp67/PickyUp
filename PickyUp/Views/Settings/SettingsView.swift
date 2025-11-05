//
// SettingsView.swift
//
// Views/Settings/SettingsView.swift
//
// Last Updated 11/4/25

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    @State private var selectedTheme: UserSettings.AppTheme = .system
    @State private var selectedMapPinStyle: UserSettings.MapPinStyle = .soccerBall
    @State private var notifyNewGames = true
    @State private var notifyMessages = true
    @State private var notifyFriendRequests = true
    @State private var showGamesPublicly = true
    
    var body: some View {
        NavigationStack {
            Form {
                // Theme Settings
                Section("Appearance") {
                    Picker("Theme", selection: $selectedTheme) {
                        Text("Light").tag(UserSettings.AppTheme.light)
                        Text("Dark").tag(UserSettings.AppTheme.dark)
                        Text("System").tag(UserSettings.AppTheme.system)
                    }
                    .onChange(of: selectedTheme) { _, newValue in
                        Task { await updateSettings() }
                    }
                    
                    Picker("Map Pin Style", selection: $selectedMapPinStyle) {
                        Text("⚽️ Soccer Ball").tag(UserSettings.MapPinStyle.soccerBall)
                        Text("🏀 Basketball").tag(UserSettings.MapPinStyle.basketball)
                        Text("📍 Default Pin").tag(UserSettings.MapPinStyle.defaultPin)
                    }
                    .onChange(of: selectedMapPinStyle) { _, newValue in
                        Task { await updateSettings() }
                    }
                }
                
                // Notification Settings
                Section("Notifications") {
                    Toggle("New Games", isOn: $notifyNewGames)
                        .onChange(of: notifyNewGames) { _, _ in
                            Task { await updateSettings() }
                        }
                    
                    Toggle("Messages", isOn: $notifyMessages)
                        .onChange(of: notifyMessages) { _, _ in
                            Task { await updateSettings() }
                        }
                    
                    Toggle("Friend Requests", isOn: $notifyFriendRequests)
                        .onChange(of: notifyFriendRequests) { _, _ in
                            Task { await updateSettings() }
                        }
                }
                
                // Game Settings
                Section("Games") {
                    Toggle("Show My Games Publicly", isOn: $showGamesPublicly)
                        .onChange(of: showGamesPublicly) { _, _ in
                            Task { await updateSettings() }
                        }
                }
                
                // Account Section
                Section("Account") {
                    Button(role: .destructive) {
                        authViewModel.signOut()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .foregroundStyle(.red)
                    }
                }
                
                // App Info
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("0.2.2")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadSettings()
            }
        }
    }
    
    func loadSettings() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        do {
            let settings = try await settingsViewModel.fetchSettings(userId: userId)
            selectedTheme = settings.theme
            selectedMapPinStyle = settings.mapPinStyle
            notifyNewGames = settings.notifyNewGames
            notifyMessages = settings.notifyMessages
            notifyFriendRequests = settings.notifyFriendRequests
            showGamesPublicly = settings.defaultShowGames
        } catch {
            print("Error loading settings: \(error)")
        }
    }

    func updateSettings() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let settings = UserSettings(
            userId: userId,
            theme: selectedTheme,
            mapPinStyle: selectedMapPinStyle,
            notifyNewGames: notifyNewGames,
            notifyMessages: notifyMessages,
            notifyFriendRequests: notifyFriendRequests,
            defaultAllowDirectMessages: true,
            defaultAllowGroupMessages: true,
            defaultShowGames: showGamesPublicly
        )
        
        do {
            try await settingsViewModel.updateSettings(settings)
        } catch {
            print("Error updating settings: \(error)")
            
        }
    }
}
