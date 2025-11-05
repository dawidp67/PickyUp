//
// UserSettings.swift
//
// Models/UserSettings.swift
//
// Last Updated 11/4/25

import Foundation
import FirebaseFirestore

struct UserSettings: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    
    // Global Settings
    var theme: AppTheme
    var mapPinStyle: MapPinStyle
    
    // Notification Settings
    var notifyNewGames: Bool
    var notifyMessages: Bool
    var notifyFriendRequests: Bool
    
    // Privacy Settings - per user settings stored separately
    var defaultAllowDirectMessages: Bool
    var defaultAllowGroupMessages: Bool
    var defaultShowGames: Bool
    
    enum AppTheme: String, Codable {
        case light
        case dark
        case system
    }
    
    enum MapPinStyle: String, Codable {
        case soccerBall
        case basketball
        case defaultPin
    }
    
    static var `default`: UserSettings {
        UserSettings(
            userId: "",
            theme: .system,
            mapPinStyle: .soccerBall,
            notifyNewGames: true,
            notifyMessages: true,
            notifyFriendRequests: true,
            defaultAllowDirectMessages: true,
            defaultAllowGroupMessages: true,
            defaultShowGames: true
        )
    }
}

// Per-user privacy settings (stored as subcollection per friendship)
struct UserPrivacySettings: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String  // Settings owner
    var targetUserId: String  // Settings apply to this user
    var allowDirectMessages: Bool
    var allowGroupMessages: Bool
    var showGames: Bool
    var canCollaborate: Bool
    
    static func defaultSettings(userId: String, targetUserId: String) -> UserPrivacySettings {
        UserPrivacySettings(
            userId: userId,
            targetUserId: targetUserId,
            allowDirectMessages: true,
            allowGroupMessages: true,
            showGames: true,
            canCollaborate: false
        )
    }
}
