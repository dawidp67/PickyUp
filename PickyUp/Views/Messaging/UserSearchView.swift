//
//  UserSearchView.swift
//  PickyUp
//
//  Created by Dawid Pankiewicz on 11/11/25.
//

import SwiftUI

struct UserSearchView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    @EnvironmentObject var messagingViewModel: MessagingViewModel

    @State private var searchText = ""
    @State private var searchResults: [AppUser] = []
    @State private var selectedMenuUser: AppUser?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var viewingProfileUser: AppUser?
    @State private var isSearching = false
    @State private var hasSearched = false
    
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Find People")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CloseToolbarButton()
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Search") {
                            Task { await searchUsers() }
                        }
                        .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
                    }
                }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name or email")
        .onChange(of: searchText) { _, newValue in
            searchTask?.cancel()
            
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                searchResults = []
                hasSearched = false
                isSearching = false
                return
            }
            
            searchTask = Task { [trimmed] in
                try? await Task.sleep(nanoseconds: 400_000_000)
                if Task.isCancelled { return }
                await searchUsers(queryOverride: trimmed)
            }
        }
        .sheet(item: $viewingProfileUser) { user in
            UserProfileView(user: user)
                .environmentObject(authViewModel)
                .environmentObject(friendshipViewModel)
                .environmentObject(messagingViewModel)
        }
        .alert("Notice", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        VStack {
            if isSearching {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Searching...")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            if isSearching {
                Spacer()
                ProgressView("Searching...")
                Spacer()
            } else if hasSearched && searchResults.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundStyle(.gray)
                    
                    Text("No users found")
                        .font(.headline)
                    
                    Text("Try searching with a different name or email")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            } else if !hasSearched {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundStyle(.gray)
                    
                    Text("Search for friends")
                        .font(.headline)
                    
                    Text("Enter a name or email to find people")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(searchResults) { user in
                            SearchResultRowView(
                                user: user,
                                onProfileTap: { viewingProfileUser = user },
                                onMenuTap: { selectedMenuUser = user }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private func searchUsers(queryOverride: String? = nil) async {
        let rawQuery = queryOverride ?? searchText
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        if query.count < 2 {
            await MainActor.run {
                self.searchResults = []
                self.hasSearched = false
                self.isSearching = false
            }
            return
        }
        
        print("🔍 Starting search for: '\(query)'")
        
        await MainActor.run { isSearching = true }
        
        do {
            let results = try await AuthService.shared.searchUsers(keyword: query)
            print("🔍 Raw results count: \(results.count)")
            
            await MainActor.run {
                self.searchResults = results.filter { $0.id != authViewModel.currentUser?.id }
                self.hasSearched = true
                self.isSearching = false
                
                print("🔍 Filtered results count: \(self.searchResults.count)")
            }
        } catch {
            print("❌ Search error: \(error.localizedDescription)")
            await MainActor.run {
                self.alertMessage = "Failed to search users: \(error.localizedDescription)"
                self.showingAlert = true
                self.hasSearched = true
                self.isSearching = false
            }
        }
    }

    private func addFriend(_ user: AppUser) async {
        guard let currentUserId = authViewModel.currentUser?.id,
              let targetUserId = user.id else {
            print("❌ Missing user IDs for friend request")
            return
        }
        
        print("📤 Sending friend request to: \(user.displayName)")
        
        do {
            try await FriendshipService.shared.sendFriendRequest(from: currentUserId, to: targetUserId)
            await MainActor.run {
                alertMessage = "Friend request sent to \(user.displayName)."
                showingAlert = true
                print("✅ Friend request sent successfully")
            }
        } catch {
            print("❌ Failed to send friend request: \(error.localizedDescription)")
            await MainActor.run {
                alertMessage = "Failed to send friend request: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }

    private func startConversation(with user: AppUser) async {
        guard let currentUser = authViewModel.currentUser,
              let currentUserId = currentUser.id else {
            print("❌ Missing current user for conversation")
            return
        }
        
        print("💬 Starting conversation with: \(user.displayName)")
        
        let conversation = await messagingViewModel.startDMConversation(
            withUser: user,
            currentUserId: currentUserId,
            currentUserName: currentUser.displayName
        )
        
        await MainActor.run {
            if conversation != nil {
                alertMessage = "Chat started with \(user.displayName)."
                print("✅ Chat started successfully")
            } else {
                alertMessage = "Failed to start chat."
                print("❌ Failed to start chat")
            }
            showingAlert = true
        }
    }
}

struct SearchResultRowView: View {
    let user: AppUser
    let onProfileTap: () -> Void
    let onMenuTap: () -> Void
    
    @State private var showMenu = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onProfileTap) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(user.initials)
                                .font(.headline)
                                .foregroundStyle(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(user.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .tint(.primary)
            
            Menu {
                Button(action: {
                    onMenuTap()
                    showMenu = false
                }) {
                    Label("View Profile", systemImage: "person.crop.circle")
                }
                
                Button(action: {
                    onMenuTap()
                    showMenu = false
                }) {
                    Label("Message", systemImage: "message.fill")
                }
                
                Button(action: {
                    onMenuTap()
                    showMenu = false
                }) {
                    Label("Add Friend", systemImage: "person.badge.plus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .tint(.secondary)
            .menuOrder(.fixed)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showMenu) {
            SearchUserActionSheet(
                user: user,
                isPresented: $showMenu
            )
        }
    }
}

struct SearchUserActionSheet: View {
    let user: AppUser
    @Binding var isPresented: Bool
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    @EnvironmentObject var messagingViewModel: MessagingViewModel
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var viewingProfile = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(user.initials)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.primary)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.headline)
                        
                        Text(user.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))
            
            Divider()
            
            VStack(spacing: 12) {
                Button(action: { viewingProfile = true }) {
                    HStack(spacing: 12) {
                        Text("👤")
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("View Profile")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("See all details")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    Task { await startConversation() }
                }) {
                    HStack(spacing: 12) {
                        Text("💬")
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Message")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("Start a chat")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    Task { await addFriend() }
                }) {
                    HStack(spacing: 12) {
                        Text("👋")
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add Friend")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("Send friend request")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
            }
            .padding()
            
            Spacer()
        }
        .background(Color(.systemGray6))
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $viewingProfile) {
            UserProfileView(user: user)
                .environmentObject(authViewModel)
                .environmentObject(friendshipViewModel)
                .environmentObject(messagingViewModel)
        }
        .alert("Notice", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func addFriend() async {
        guard let currentUserId = authViewModel.currentUser?.id,
              let targetUserId = user.id else { return }
        
        do {
            try await FriendshipService.shared.sendFriendRequest(from: currentUserId, to: targetUserId)
            await MainActor.run {
                alertMessage = "Friend request sent to \(user.displayName)."
                showAlert = true
                isPresented = false
            }
        } catch {
            await MainActor.run {
                alertMessage = "Failed to send friend request: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func startConversation() async {
        guard let currentUser = authViewModel.currentUser,
              let currentUserId = currentUser.id else { return }
        
        let conversation = await messagingViewModel.startDMConversation(
            withUser: user,
            currentUserId: currentUserId,
            currentUserName: currentUser.displayName
        )
        
        await MainActor.run {
            if conversation != nil {
                alertMessage = "Chat started with \(user.displayName)."
                showAlert = true
                isPresented = false
            } else {
                alertMessage = "Failed to start chat."
                showAlert = true
            }
        }
    }
}

#Preview {
    UserSearchView()
        .environmentObject(AuthViewModel())
        .environmentObject(FriendshipViewModel())
        .environmentObject(MessagingViewModel())
}
