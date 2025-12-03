//
// MessagingView.swift
//
// Views/Messaging/MessagingView.swift
//
// Last Updated 11/7/25

import SwiftUI

struct MessagingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    
    @State private var showingSearch = false
    @State private var showingCreateGroup = false
    @State private var selectedConversationId: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if messagingViewModel.conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationsList
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateGroup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSearch) {
                UserSearchView()
                    .environmentObject(authViewModel)
                    .environmentObject(messagingViewModel)
                    .environmentObject(friendshipViewModel)
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupChatView()
                    .environmentObject(authViewModel)
                    .environmentObject(messagingViewModel)
                    .environmentObject(friendshipViewModel)
            }
            .navigationDestination(item: $selectedConversationId) { conversationId in
                ChatView(conversationId: conversationId)
                    .environmentObject(authViewModel)
                    .environmentObject(messagingViewModel)
                    .environmentObject(friendshipViewModel)
            }
            .onAppear {
                setupMessagingListener()
            }
            .refreshable {
                // Pull to refresh - re-setup listener
                setupMessagingListener()
            }
        }
    }
    
    private var conversationsList: some View {
        List {
            ForEach(messagingViewModel.conversations) { conversation in
                ConversationRowView(conversation: conversation)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedConversationId = conversation.id
                    }
            }
            .onDelete(perform: deleteConversations)
        }
        .listStyle(.plain)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "message")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No Messages Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a conversation with someone!")
                .foregroundStyle(.secondary)
            
            Button {
                showingSearch = true
            } label: {
                Label("Find People", systemImage: "magnifyingglass")
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private func setupMessagingListener() {
        guard let userId = authViewModel.currentUser?.id else { return }
        messagingViewModel.setupConversationsListener(userId: userId)
        print("📱 Set up conversations listener for user: \(userId)")
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = messagingViewModel.conversations[index]
            if let conversationId = conversation.id {
                Task {
                    await messagingViewModel.deleteConversation(conversationId: conversationId)
                }
            }
        }
    }
}

// MARK: - Conversation Row
struct ConversationRowView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(getInitials())
                        .font(.headline)
                        .foregroundStyle(.primary) // changed from .blue to adaptive
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(getConversationName())
                    .font(.headline)
                
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let timestamp = conversation.lastMessageTimestamp {
                Text(formatTimestamp(timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func getConversationName() -> String {
        guard let currentUserId = authViewModel.currentUser?.id else { return "Unknown" }
        
        switch conversation.type {
        case .directMessage:
            return conversation.otherUserName(currentUserId: currentUserId) ?? "Unknown"
        case .groupChat, .gameAnnouncement:
            return conversation.groupName ?? "Group Chat"
        }
    }
    
    private func getInitials() -> String {
        let name = getConversationName()
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

