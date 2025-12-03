//
// NotificationService.swift
//
// Services/NotificationService.swift
//
// Last Updated 11/10/25

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Notification Service
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
        fromUserId: String,
        friendshipId: String? = nil,
        gameId: String? = nil,
        conversationId: String? = nil
    ) async throws {
        var fromUserName: String?
        do {
            let fromUser = try await UserService.shared.getUser(userId: fromUserId)
            fromUserName = fromUser.displayName
        } catch {
            print("⚠️ Could not fetch sender name: \(error.localizedDescription)")
        }
        
        let notification = AppNotification(
            id: nil,
            userId: userId,
            type: type,
            title: title,
            message: message,
            timestamp: Date(),
            isRead: false,
            actionTaken: false,
            fromUserId: fromUserId,
            fromUserName: fromUserName,
            friendshipId: friendshipId,
            conversationId: conversationId,
            gameId: gameId
        )
        
        try db.collection("notifications").addDocument(from: notification)
        print("✅ Notification created for user: \(userId), type: \(type.rawValue)")
    }
    
    // MARK: - Get Notifications
    func getNotifications(userId: String, limit: Int = 50) async throws -> [AppNotification] {
        let snapshot = try await db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: AppNotification.self) }
    }
    
    // MARK: - Listen to Notifications
    func listenToNotifications(userId: String, completion: @escaping ([AppNotification]) -> Void) -> ListenerRegistration {
        return db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Notification listener error: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let notifications = documents.compactMap { try? $0.data(as: AppNotification.self) }
                completion(notifications)
            }
    }
    
    // MARK: - Mark as Read
    func markAsRead(notificationId: String) async throws {
        try await db.collection("notifications")
            .document(notificationId)
            .updateData(["isRead": true])
    }
    
    // MARK: - Mark Action Taken
    func markActionTaken(notificationId: String) async throws {
        try await db.collection("notifications")
            .document(notificationId)
            .updateData([
                "actionTaken": true,
                "isRead": true
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
        try await db.collection("notifications")
            .document(notificationId)
            .delete()
    }
    
    // MARK: - Delete All Notifications
    func deleteAllNotifications(userId: String) async throws {
        let snapshot = try await db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let batch = db.batch()
        
        for document in snapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
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
    
    // MARK: - Delete Notification by Context
    func deleteNotificationsByContext(userId: String, friendshipId: String) async throws {
        let snapshot = try await db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .whereField("friendshipId", isEqualTo: friendshipId)
            .getDocuments()
        
        let batch = db.batch()
        
        for document in snapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        try await batch.commit()
    }
}
