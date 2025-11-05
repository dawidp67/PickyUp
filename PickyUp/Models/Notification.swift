//
// Notification.swift
//
// Models/Notification.swift
//
// Last Updated 11/4/25

import Foundation
import FirebaseFirestore

// MARK: - Notification Type
enum NotificationType: String, Codable {
    case friendRequest
    case friendAccepted
    case newMessage
    case newGame
    case gameUpdate
    case gameReminder
    case blocked
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
    var relatedId: String?
    var fromUserId: String?
    var fromUserName: String?
    var friendshipId: String?
    var gameId: String?
    var conversationId: String?
    
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
        gameId: String? = nil,
        conversationId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.actionTaken = actionTaken
        self.relatedId = relatedId
        self.fromUserId = fromUserId
        self.fromUserName = fromUserName
        self.friendshipId = friendshipId
        self.gameId = gameId
        self.conversationId = conversationId
    }
}
