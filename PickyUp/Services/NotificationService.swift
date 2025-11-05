//
// NotificationService.swift
//
// Services/NotificationService.swift
//
// Last Updated 11/4/25

import Foundation
import FirebaseFirestore

class NotificationService {
    static let shared = NotificationService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Create Notification
    func createNotification(
        userId: String,
        type: NotificationType,
        title: String,
        message: String,
        fromUserId: String? = nil,
        gameId: String? = nil,
        friendshipId: String? = nil
    ) async throws {
        var fromUserName: String? = nil
        
        if let fromId = fromUserId {
            let userDoc = try await db.collection("users").document(fromId).getDocument()
            fromUserName = userDoc.data()?["displayName"] as? String
        }
        
        let notification = AppNotification(
            userId: userId,
            type: type,
            title: title,
            message: message,
            timestamp: Date(),
            isRead: false,
            actionTaken: false,
            relatedId: nil,
            fromUserId: fromUserId,
            fromUserName: fromUserName,
            friendshipId: friendshipId,
            gameId: gameId,
            conversationId: nil
        )
        
        try db.collection("notifications").addDocument(from: notification)
    }
    
    // MARK: - Get Notifications (alias for fetchNotifications)
    func getNotifications(userId: String) async throws -> [AppNotification] {
        return try await fetchNotifications(userId: userId)
    }
    
    // MARK: - Fetch Notifications
    func fetchNotifications(userId: String) async throws -> [AppNotification] {
        let snapshot = try await db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: AppNotification.self) }
    }
    
    // MARK: - Listen to Notifications
    func listenToNotifications(userId: String, completion: @escaping ([AppNotification]) -> Void) -> ListenerRegistration {
        return db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let notifications = documents.compactMap { try? $0.data(as: AppNotification.self) }
                completion(notifications)
            }
    }
    
    // MARK: - Mark as Read
    func markAsRead(notificationId: String) async throws {
        try await db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ])
    }
    
    // MARK: - Mark Action Taken
    func markActionTaken(notificationId: String) async throws {
        try await db.collection("notifications").document(notificationId).updateData([
            "actionTaken": true
        ])
    }
    
    // MARK: - Mark All as Read
    func markAllAsRead(userId: String) async throws {
        let snapshot = try await db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        let batch = db.batch()
        for document in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: document.reference)
        }
        try await batch.commit()
    }
    
    // MARK: - Delete Notification
    func deleteNotification(notificationId: String) async throws {
        try await db.collection("notifications").document(notificationId).delete()
    }
    
    // MARK: - Delete All for User
    func deleteAllNotifications(userId: String) async throws {
        let snapshot = try await db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let batch = db.batch()
        snapshot.documents.forEach { batch.deleteDocument($0.reference) }
        try await batch.commit()
    }
    
    // MARK: - Get Unread Count
    func getUnreadCount(userId: String) async throws -> Int {
        let snapshot = try await db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        return snapshot.documents.count
    }
}
