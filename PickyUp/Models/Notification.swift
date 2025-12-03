//
// Notification.swift
//
// Models/Notification.swift
//
// Last Updated 11/16/25

import Foundation
import FirebaseFirestore

// MARK: - Notification Type
enum NotificationType: String, Codable {
    case friendRequest = "friendRequest"
    case friendAccepted = "friendAccepted"
    case newMessage = "newMessage"
    case newGame = "newGame"
    case gameUpdate = "gameUpdate"
    case gameReminder = "gameReminder"
    case blocked = "blocked"
}

// MARK: - App Notification
struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var type: NotificationType
    var title: String
    var message: String
    var timestamp: Date
    var isRead: Bool
    var actionTaken: Bool
    
    // Optional fields for additional context
    var relatedId: String? // Generic field for backward compatibility
    var fromUserId: String?
    var fromUserName: String?
    var friendshipId: String?
    var conversationId: String?
    var gameId: String?
    
    // Coding keys for Firestore
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case type
        case title
        case message
        case timestamp
        case isRead
        case actionTaken
        case relatedId
        case fromUserId
        case fromUserName
        case friendshipId
        case conversationId
        case gameId
    }
    
    // Initializer with default values
    init(
        id: String? = nil,
        userId: String,
        type: NotificationType,
        title: String,
        message: String,
        timestamp: Date = Date(),
        isRead: Bool = false,
        actionTaken: Bool = false,
        relatedId: String? = nil,
        fromUserId: String? = nil,
        fromUserName: String? = nil,
        friendshipId: String? = nil,
        conversationId: String? = nil,
        gameId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.actionTaken = actionTaken
        self.relatedId = relatedId ?? friendshipId ?? conversationId ?? gameId
        self.fromUserId = fromUserId
        self.fromUserName = fromUserName
        self.friendshipId = friendshipId
        self.conversationId = conversationId
        self.gameId = gameId
    }
}
