//
// MessagingService.swift
//
// Services/MessagingService.swift
//
// Last Updated 11/16/25

import Foundation
import FirebaseFirestore


class MessagingService {
    static let shared = MessagingService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Create Conversation
    func createConversation(
        type: ConversationType,
        participantIds: [String],
        participantNames: [String: String],
        groupName: String? = nil,
        gameId: String? = nil,
        createdBy: String
    ) async throws -> String {
        let conversation = Conversation(
            id: nil,
            type: type,
            participantIds: participantIds,
            participantNames: participantNames,
            lastMessage: nil,
            lastMessageTimestamp: nil,
            lastMessageSenderId: nil,
            createdAt: Date(),
            createdBy: createdBy,
            groupName: groupName,
            groupPhotoURL: nil,
            gameId: gameId
        )
        
        let docRef = try db.collection("conversations").addDocument(from: conversation)
        return docRef.documentID
    }
    
    // MARK: - Get or Create DM Conversation
    func getOrCreateDMConversation(
        userId1: String,
        userId2: String,
        userName1: String,
        userName2: String
    ) async throws -> Conversation {
        let sortedIds = [userId1, userId2].sorted()
        
        let query = db.collection("conversations")
            .whereField("type", isEqualTo: ConversationType.directMessage.rawValue)
            .whereField("participantIds", arrayContains: userId1)
        
        let snapshot = try await query.getDocuments()
        
        for document in snapshot.documents {
            if let conversation = try? document.data(as: Conversation.self),
               conversation.participantIds.sorted() == sortedIds {
                return conversation
            }
        }
        
        // Create new conversation
        let participantNames = [userId1: userName1, userId2: userName2]
        let conversationId = try await createConversation(
            type: .directMessage,
            participantIds: sortedIds,
            participantNames: participantNames,
            createdBy: userId1
        )
        
        // Fetch and return the created conversation
        let docSnapshot = try await db.collection("conversations").document(conversationId).getDocument()
        guard let conversation = try? docSnapshot.data(as: Conversation.self) else {
            throw NSError(domain: "MessagingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create conversation"])
        }
        
        return conversation
    }
    
    // MARK: - Get or Create Direct Conversation (Legacy method)
    func getOrCreateDirectConversation(
        userId1: String,
        userId2: String,
        user1Name: String,
        user2Name: String
    ) async throws -> String {
        let conversation = try await getOrCreateDMConversation(
            userId1: userId1,
            userId2: userId2,
            userName1: user1Name,
            userName2: user2Name
        )
        return conversation.id ?? ""
    }
    
    // MARK: - Create Group Chat
    func createGroupChat(
        name: String,
        participantIds: [String],
        participantNames: [String: String],
        creatorId: String
    ) async throws -> String {
        return try await createConversation(
            type: .groupChat,
            participantIds: participantIds,
            participantNames: participantNames,
            groupName: name,
            createdBy: creatorId
        )
    }
    
    // MARK: - Send Message
    func sendMessage(conversationId: String, senderId: String, senderName: String, text: String) async throws -> String {
        let message = Message(
            id: nil,
            conversationId: conversationId,
            senderId: senderId,
            senderName: senderName,
            text: text,
            timestamp: Date(),
            readBy: [senderId]
        )
        
        let docRef = try db.collection("messages").addDocument(from: message)
        
        // Update conversation's last message
        try await db.collection("conversations").document(conversationId).updateData([
            "lastMessage": text,
            "lastMessageTimestamp": Timestamp(date: Date()),
            "lastMessageSenderId": senderId
        ])
        
        // Create notifications for other participants
        do {
            let conversationDoc = try await db.collection("conversations").document(conversationId).getDocument()
            if let conversation = try? conversationDoc.data(as: Conversation.self) {
                for participantId in conversation.participantIds where participantId != senderId {
                    try await NotificationService.shared.createNotification(
                        userId: participantId,
                        type: .newMessage,
                        title: "New Message",
                        message: "\(senderName): \(text)",
                        fromUserId: senderId,
                        conversationId: conversationId
                    )
                }
                print("✅ Message notifications sent")
            }
        } catch {
            print("⚠️ Failed to create message notifications: \(error.localizedDescription)")
        }
        
        return docRef.documentID
    }
    
    // MARK: - Fetch Messages
    func fetchMessages(conversationId: String, limit: Int = 50) async throws -> [Message] {
        let snapshot = try await db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Message.self) }.reversed()
    }
    
    // MARK: - Mark Messages as Read
    func markMessagesAsRead(conversationId: String, userId: String) async throws {
        let snapshot = try await db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .getDocuments()
        
        let batch = db.batch()
        
        for document in snapshot.documents {
            if var message = try? document.data(as: Message.self),
               !message.readBy.contains(userId) {
                message.readBy.append(userId)
                batch.updateData(["readBy": message.readBy], forDocument: document.reference)
            }
        }
        
        try await batch.commit()
    }
    
    // MARK: - Mark Message as Read
    func markMessageAsRead(conversationId: String, messageId: String, userId: String) async throws {
        let messageRef = db.collection("messages").document(messageId)
        let doc = try await messageRef.getDocument()
        
        if var message = try? doc.data(as: Message.self),
           !message.readBy.contains(userId) {
            message.readBy.append(userId)
            try await messageRef.updateData(["readBy": message.readBy])
        }
    }
    
    // MARK: - Get User Conversations
    func getUserConversations(userId: String) async throws -> [Conversation] {
        let snapshot = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Conversation.self) }
    }
    
    // MARK: - Listen to Conversations
    func listenToConversations(userId: String, completion: @escaping ([Conversation]) -> Void) -> ListenerRegistration {
        return db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let conversations = documents.compactMap { try? $0.data(as: Conversation.self) }
                completion(conversations)
            }
    }
    
    // MARK: - Listen to Messages
    func listenToMessages(conversationId: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        return db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let messages = documents.compactMap { try? $0.data(as: Message.self) }
                completion(messages)
            }
    }
    
    // MARK: - Delete Conversation
    func deleteConversation(conversationId: String) async throws {
        let messagesSnapshot = try await db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .getDocuments()
        
        let batch = db.batch()
        messagesSnapshot.documents.forEach { batch.deleteDocument($0.reference) }
        batch.deleteDocument(db.collection("conversations").document(conversationId))
        
        try await batch.commit()
    }
    
    // MARK: - Add Participant
    func addParticipant(conversationId: String, userId: String, userName: String) async throws {
        let conversationRef = db.collection("conversations").document(conversationId)
        
        try await conversationRef.updateData([
            "participantIds": FieldValue.arrayUnion([userId]),
            "participantNames.\(userId)": userName
        ])
    }
    
    // MARK: - Remove Participant
    func removeParticipant(conversationId: String, userId: String) async throws {
        let conversationRef = db.collection("conversations").document(conversationId)
        
        try await conversationRef.updateData([
            "participantIds": FieldValue.arrayRemove([userId]),
            "participantNames.\(userId)": FieldValue.delete()
        ])
    }
}
