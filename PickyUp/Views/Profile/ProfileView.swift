//
// ProfileView.swift
//
// Views/Profile/ProfileView.swift
//
// Last Updated 11/16/25

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingEditProfile = false
    @State private var showingNotifications = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            if let urlString = authViewModel.currentUser?.profilePhotoURL,
                               let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 100, height: 100)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    case .failure:
                                        initialsCircle
                                    @unknown default:
                                        initialsCircle
                                    }
                                }
                            } else {
                                initialsCircle
                            }
                        }
                        
                        if let user = authViewModel.currentUser {
                            Text(user.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            showingEditProfile = true
                        } label: {
                            Text("Edit Profile")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.top)
                    
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(gameViewModel.userCreatedGames.count)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Created")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack {
                            Text("\(profileViewModel.attendingGames.count)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Attending")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack {
                            Text("\(friendshipViewModel.friends.count)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Friends")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if !gameViewModel.userCreatedGames.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Games")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(gameViewModel.userCreatedGames) { game in
                                NavigationLink {
                                    GameDetailView(game: game)
                                } label: {
                                    GameCardView(game: game)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    if !profileViewModel.attendingGames.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Attending")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(profileViewModel.attendingGames) { game in
                                NavigationLink {
                                    GameDetailView(game: game)
                                } label: {
                                    GameCardView(game: game)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingNotifications = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.title3)
                            
                            if notificationViewModel.unreadCount > 0 {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 18, height: 18)
                                    
                                    Text("\(notificationViewModel.unreadCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationView()
                    .environmentObject(notificationViewModel)
                    .environmentObject(authViewModel)
                    .environmentObject(friendshipViewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(authViewModel)
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await gameViewModel.fetchUserCreatedGames(userId: userId)
                    await profileViewModel.fetchAttendingGames(userId: userId)
                }
            }
            .refreshable {
                if let userId = authViewModel.currentUser?.id {
                    await gameViewModel.fetchUserCreatedGames(userId: userId)
                    await profileViewModel.fetchAttendingGames(userId: userId)
                }
            }
        }
    }
    
    private var initialsCircle: some View {
        ZStack {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 100, height: 100)
            Text(authViewModel.currentUser?.initials ?? "?")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
