import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var gameViewModel: GameViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.gradient)
                                .frame(width: 100, height: 100)
                            
                            Text(authViewModel.currentUser?.initials ?? "?").font(.system(size: 40, weight: .semibold))
                                .foregroundStyle(.white)
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
                    
                    Button(role: .destructive) {
                        authViewModel.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
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
}
