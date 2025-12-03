//
// FriendSystemTestView.swift
//
// Views/Testing/FriendSystemTestView.swift
//
// DEBUGGING ONLY - Remove from production
//
// Last Updated 11/11/25
//

import SwiftUI

struct FriendSystemTestView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    
    @State private var testUserId = ""
    @State private var testOutput = ""
    @State private var isRunningTest = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusSection
                    Divider()
                    testActionsSection
                    Divider()
                    manualTestSection
                    Divider()
                    outputSection
                }
                .padding()
            }
            .navigationTitle("🧪 Friend System Test")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let userId = authViewModel.currentUser?.id {
                    friendshipViewModel.startListening(userId: userId)
                }
            }
        }
    }
    
    // MARK: - Sections
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Status").font(.headline)
            
            if let currentUser = authViewModel.currentUser {
                HStack {
                    Text("User:")
                    Spacer()
                    Text(currentUser.displayName).foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("User ID:")
                    Spacer()
                    Text(currentUser.id ?? "nil")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Text("Friends:")
                Spacer()
                Text("\(friendshipViewModel.friends.count)").foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Pending Requests:")
                Spacer()
                Text("\(friendshipViewModel.pendingRequests.count)").foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Notifications:")
                Spacer()
                Text("\(notificationViewModel.notifications.count)").foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Unread:")
                Spacer()
                Text("\(notificationViewModel.unreadCount)")
                    .foregroundStyle(.red)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var testActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Tests").font(.headline)
            
            Button {
                runListenerTest()
            } label: {
                Label("Test Listeners", systemImage: "antenna.radiowaves.left.and.right")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }.disabled(isRunningTest)
            
            Button {
                runFriendshipTest()
            } label: {
                Label("Test Friendship Queries", systemImage: "person.2")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }.disabled(isRunningTest)
            
            Button {
                runNotificationTest()
            } label: {
                Label("Test Notifications", systemImage: "bell")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }.disabled(isRunningTest)
            
            Button {
                testOutput = ""
            } label: {
                Label("Clear Log", systemImage: "trash")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    private var manualTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manual Test").font(.headline)
            Text("Send test friend request to:")
                .font(.subheadline).foregroundStyle(.secondary)
            
            TextField("Enter User ID", text: $testUserId)
                .textFieldStyle(.roundedBorder)
            
            Button {
                sendTestFriendRequest()
            } label: {
                Label("Send Friend Request", systemImage: "paperplane")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.purple)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            .disabled(testUserId.isEmpty || isRunningTest)
        }
    }
    
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test Output").font(.headline)
            
            ScrollView {
                Text(testOutput.isEmpty ? "No output yet..." : testOutput)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 200)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Test Functions
    private func addLog(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        testOutput += "[\(timestamp)] \(message)\n"
        print("🧪 \(message)")
    }
    
    private func runListenerTest() {
        isRunningTest = true
        addLog("=== LISTENER TEST ===")
        
        Task {
            defer { isRunningTest = false }
            
            guard let userId = authViewModel.currentUser?.id else {
                addLog("❌ No current user")
                return
            }
            
            addLog("✅ Current user: \(userId)")
            addLog("📊 Friends: \(friendshipViewModel.friends.count)")
            addLog("📊 Pending: \(friendshipViewModel.pendingRequests.count)")
            addLog("📊 Notifications: \(notificationViewModel.notifications.count)")
            addLog("📊 Unread: \(notificationViewModel.unreadCount)")
            
            addLog("🎧 Checking listeners...")
            await Task.sleep(1_000_000_000)
            addLog("✅ Listeners check complete")
            addLog("=== TEST COMPLETE ===\n")
        }
    }
    
    private func runFriendshipTest() {
        isRunningTest = true
        addLog("=== FRIENDSHIP TEST ===")
        
        Task {
            defer { isRunningTest = false }
            
            let friends = friendshipViewModel.friends
            addLog("📊 Found \(friends.count) friends")
            for friend in friends {
                addLog("  - Friend: \(friend.otherUserId(currentUserId: authViewModel.currentUser?.id ?? ""))")
            }
            
            let pending = friendshipViewModel.pendingRequests
            addLog("📊 Found \(pending.count) pending requests")
            for request in pending {
                addLog("  - From: \(request.requesterId)")
            }
            
            addLog("=== TEST COMPLETE ===\n")
        }
    }
    
    private func runNotificationTest() {
        isRunningTest = true
        addLog("=== NOTIFICATION TEST ===")
        
        Task {
            defer { isRunningTest = false }
            
            guard let userId = authViewModel.currentUser?.id else { return }
            
            do {
                let notifications = try await NotificationService.shared.getNotifications(userId: userId)
                addLog("✅ Found \(notifications.count) notifications")
                for n in notifications.prefix(5) {
                    addLog("  - \(n.type.rawValue): \(n.message) From: \(n.fromUserName ?? "Unknown") Read: \(n.isRead)")
                }
                
                let unreadCount = try await NotificationService.shared.getUnreadCount(userId: userId)
                addLog("✅ Unread count: \(unreadCount)")
            } catch {
                addLog("❌ Error: \(error.localizedDescription)")
            }
            
            addLog("=== TEST COMPLETE ===\n")
        }
    }
    
    private func sendTestFriendRequest() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isRunningTest = true
        addLog("=== SEND FRIEND REQUEST TEST ===")
        addLog("📤 Sending friend request to: \(testUserId)")
        
        Task {
            defer { isRunningTest = false }
            await friendshipViewModel.sendFriendRequest(to: testUserId, from: userId)
            
            if let error = friendshipViewModel.errorMessage {
                addLog("❌ Error: \(error)")
            } else if let success = friendshipViewModel.successMessage {
                addLog("✅ Success: \(success)")
            }
            
            addLog("=== TEST COMPLETE ===\n")
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FriendSystemTestView()
            .environmentObject(AuthViewModel())
            .environmentObject(NotificationViewModel())
            .environmentObject(FriendshipViewModel())
    }
}
