//
// Message.swift
//
// Models/Message.swift
//
// Last Updated 11/4/25

import Foundation
import FirebaseFirestore

// MARK: - Conversation Type
enum ConversationType: String, Codable {
    case directMessage
    case groupChat
    case gameAnnouncement
}

// MARK: - Individual Message
struct Message: Codable, Identifiable {
    @DocumentID var id: String?
    var conversationId: String
    var senderId: String
    var senderName: String
    var text: String
    var timestamp: Date
    var readBy: [String] // Array of user IDs who have read the message
    
    var isRead: Bool {
        !readBy.isEmpty
    }
}

// MARK: - Conversation (DM or Group Chat)
struct Conversation: Codable, Identifiable {
    @DocumentID var id: String?
    var type: ConversationType
    var participantIds: [String]
    var participantNames: [String: String] // userId: displayName
    var lastMessage: String?
    var lastMessageTimestamp: Date?
    var lastMessageSenderId: String?
    var createdAt: Date
    var createdBy: String
    
    // For group chats
    var groupName: String?
    var groupPhotoURL: String?
    
    // For game announcements
    var gameId: String?
    
    // MARK: - Helpers
    func otherUserId(currentUserId: String) -> String? {
        guard type == .directMessage else { return nil }
        return participantIds.first { $0 != currentUserId }
    }
    
    func otherUserName(currentUserId: String) -> String? {
        guard let otherId = otherUserId(currentUserId: currentUserId) else { return nil }
        return participantNames[otherId]
    }
}
