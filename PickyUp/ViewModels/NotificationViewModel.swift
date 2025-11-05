//
// NotificationViewModel.swift
//
// ViewModels/NotificationViewModel.swift
//
// Last Updated 11/4/25

import Foundation
import FirebaseFirestore

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let notificationService = NotificationService.shared
    private var notificationsListener: ListenerRegistration?
    
    deinit {
        notificationsListener?.remove()
    }
    
    // MARK: - Setup Listener
    func setupNotificationsListener(userId: String) {
        notificationsListener = notificationService.listenToNotifications(userId: userId) { [weak self] notifications in
            Task { @MainActor in
                self?.notifications = notifications
                self?.unreadCount = notifications.filter { !$0.isRead }.count
            }
        }
    }
    
    // MARK: - Fetch Notifications
    func fetchNotifications(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedNotifications = try await notificationService.getNotifications(userId: userId)
            notifications = fetchedNotifications
            unreadCount = fetchedNotifications.filter { !$0.isRead }.count
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Mark as Read
    func markAsRead(notification: AppNotification) async {
        guard let notificationId = notification.id else { return }
        
        do {
            try await notificationService.markAsRead(notificationId: notificationId)
            
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                notifications[index].isRead = true
                unreadCount = notifications.filter { !$0.isRead }.count
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Mark Action Taken
    func markActionTaken(notification: AppNotification) async {
        guard let notificationId = notification.id else { return }
        
        do {
            try await notificationService.markActionTaken(notificationId: notificationId)
            
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                notifications[index].actionTaken = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Mark All as Read
    func markAllAsRead(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await notificationService.markAllAsRead(userId: userId)
            
            // Update local state
            for index in notifications.indices {
                notifications[index].isRead = true
            }
            unreadCount = 0
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Delete Notification
    func deleteNotification(notification: AppNotification) async {
        guard let notificationId = notification.id else { return }
        
        do {
            try await notificationService.deleteNotification(notificationId: notificationId)
            
            // Remove from local state
            notifications.removeAll { $0.id == notificationId }
            unreadCount = notifications.filter { !$0.isRead }.count
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Delete All Notifications
    func deleteAllNotifications(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await notificationService.deleteAllNotifications(userId: userId)
            notifications = []
            unreadCount = 0
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Get Unread Notifications
    var unreadNotifications: [AppNotification] {
        notifications.filter { !$0.isRead }
    }
    
    // MARK: - Get Read Notifications
    var readNotifications: [AppNotification] {
        notifications.filter { $0.isRead }
    }
    
    // MARK: - Get Friend Request Notifications
    var friendRequestNotifications: [AppNotification] {
        notifications.filter { $0.type == .friendRequest && !$0.actionTaken }
    }
    
    // MARK: - Clear Error
    func clearError() {
        errorMessage = nil
    }
}
