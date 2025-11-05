//
// SettingsViewModel.swift
//
// ViewModels/SettingsViewModel.swift
//
// Last Updated 11/4/25

import Foundation
import FirebaseFirestore

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var userSettings: UserSettings?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func fetchSettings(userId: String) async throws -> UserSettings {
        let document = try await db.collection("userSettings").document(userId).getDocument()
        
        if document.exists, let settings = try? document.data(as: UserSettings.self) {
            self.userSettings = settings
            return settings
        } else {
            // Create default settings
            let defaultSettings = UserSettings.default
            var settings = defaultSettings
            settings.userId = userId
            
            try await updateSettings(settings)
            self.userSettings = settings
            return settings
        }
    }
    
    func updateSettings(_ settings: UserSettings) async throws {
        try db.collection("userSettings").document(settings.userId).setData(from: settings)
        self.userSettings = settings
    }
    
    func updateTheme(userId: String, theme: UserSettings.AppTheme) async throws {
        guard var settings = userSettings else {
            _ = try await fetchSettings(userId: userId)
            return
        }
        
        settings.theme = theme
        try await updateSettings(settings)
    }
    
    func updateMapPinStyle(userId: String, style: UserSettings.MapPinStyle) async throws {
        guard var settings = userSettings else {
            _ = try await fetchSettings(userId: userId)
            return
        }
        
        settings.mapPinStyle = style
        try await updateSettings(settings)
    }
    
    func updateNotificationSettings(userId: String, newGames: Bool, messages: Bool, friendRequests: Bool) async throws {
        guard var settings = userSettings else {
            _ = try await fetchSettings(userId: userId)
            return
        }
        
        settings.notifyNewGames = newGames
        settings.notifyMessages = messages
        settings.notifyFriendRequests = friendRequests
        try await updateSettings(settings)
    }
}
