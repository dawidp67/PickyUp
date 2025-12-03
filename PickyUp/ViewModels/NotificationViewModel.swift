//
//  NotificationViewModel.swift
//  PickyUp
//
//  Created by ChatGPT on 11/11/25.
//

import Foundation
import FirebaseFirestore

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var errorMessage: String? = nil

    private var listener: ListenerRegistration?

    // MARK: - Setup Listener
    func setupNotificationsListener(userId: String) {
        listener?.remove()
        listener = NotificationService.shared.listenToNotifications(userId: userId) { [weak self] result in
            Task { @MainActor in
                self?.notifications = result
                self?.unreadCount = result.filter { !$0.isRead }.count
            }
        }
    }

    func removeListener() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Mark as Read
    func markAsRead(notificationId: String) async {
        do {
            try await NotificationService.shared.markAsRead(notificationId: notificationId)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func markAllAsRead(userId: String) async {
        do {
            try await NotificationService.shared.markAllAsRead(userId: userId)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
