//
//  GameDetailView.swift (Updated)
//  PickyUp
//

import SwiftUI
import MapKit

struct GameDetailView: View {
    let game: Game
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var rsvps: [RSVP] = []
    @State private var userRSVP: RSVP?
    @State private var isLoading = false
    @State private var showingDeleteAlert = false
    @State private var showingEditGame = false
    @State private var selectedUser: User?
    
    var isCreator: Bool {
        game.creatorId == authViewModel.currentUser?.id
    }
    
    var goingCount: Int {
        rsvps.filter { $0.status == .going }.count
    }
    
    var maybeCount: Int {
        rsvps.filter { $0.status == .maybe }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                mainContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditGame) {
                EditGameView(game: game)
            }
            .sheet(item: $selectedUser) { user in
                UserProfileView(user: user)
                    .environmentObject(authViewModel)
            }
            .alert("Delete Game?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteGame()
                    }
                }
            } message: {
                Text("This will permanently delete this game and notify all attendees.")
            }
            .task {
                await fetchRSVPs()
                await fetchUserRSVP()
            }
        }
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            Divider()
            dateTimeSection
            Divider()
            locationSection
            
            if let description = game.description, !description.isEmpty {
                Divider()
                descriptionSection(description)
            }
            
            Divider()
            attendeesSection
            
            if !isCreator {
                rsvpButtons
            }
            
            if isCreator {
                deleteButton
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(game.sportType.icon)
                    .font(.system(size: 50))
                
                VStack(alignment: .leading) {
                    Text(game.displaySportName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Button {
                        Task {
                            await loadUser(userId: game.creatorId)
                        }
                    } label: {
                        Text("by \(game.creatorName)")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
                
                Spacer()
                
                if isCreator {
                    Button {
                        showingEditGame = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.dateTime.relativeDateString)
                        .font(.headline)
                    Text(game.dateTime.timeString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
            }
            
            Label {
                Text("\(game.duration) minutes")
            } icon: {
                Image(systemName: "clock")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location", systemImage: "mappin.circle")
                .font(.headline)
                .foregroundStyle(.blue)
            
            Text(game.location.address)
                .font(.subheadline)
            
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                center: game.location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )), annotationItems: [game]) { game in
                MapMarker(coordinate: game.location.coordinate, tint: .red)
            }
            .frame(height: 200)
            .cornerRadius(12)
            .allowsHitTesting(false)
        }
        .padding(.horizontal)
    }
    
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var attendeesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attendees")
                .font(.headline)
            
            HStack(spacing: 20) {
                Label("\(goingCount) Going", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Label("\(maybeCount) Maybe", systemImage: "questionmark.circle.fill")
                    .foregroundStyle(.orange)
            }
            .font(.subheadline)
            
            if !rsvps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(rsvps) { rsvp in
                        Button {
                            Task {
                                await loadUser(userId: rsvp.userId)
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(rsvp.status == .going ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text(rsvp.userName)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(rsvp.status.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    private var rsvpButtons: some View {
        VStack(spacing: 12) {
            if userRSVP?.status == .going {
                Button {
                    Task { await removeRSVP() }
                } label: {
                    Label("Cancel RSVP", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            } else {
                Button {
                    Task { await rsvpToGame(status: .going) }
                } label: {
                    Label("I'm Going!", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            }
            
            if userRSVP?.status == .maybe {
                Button {
                    Task { await removeRSVP() }
                } label: {
                    Label("Cancel Maybe", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            } else {
                Button {
                    Task { await rsvpToGame(status: .maybe) }
                } label: {
                    Label("Maybe", systemImage: "questionmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label: {
            Label("Delete Game", systemImage: "trash")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundStyle(.white)
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Functions
    
    func loadUser(userId: String) async {
        do {
            let user = try await UserService.shared.fetchUser(userId: userId)
            selectedUser = user
        } catch {
            print("Error loading user: \(error)")
        }
    }
    
    func fetchRSVPs() async {
        guard let gameId = game.id else { return }
        do {
            rsvps = try await RSVPService.shared.fetchRSVPs(gameId: gameId)
        } catch {
            print("Error fetching RSVPs: \(error)")
        }
    }
    
    func fetchUserRSVP() async {
        guard let gameId = game.id,
              let userId = authViewModel.currentUser?.id else { return }
        do {
            userRSVP = try await RSVPService.shared.fetchUserRSVP(gameId: gameId, userId: userId)
        } catch {
            print("Error fetching user RSVP: \(error)")
        }
    }
    
    func rsvpToGame(status: RSVPStatus) async {
        guard let gameId = game.id,
              let user = authViewModel.currentUser else { return }
        
        isLoading = true
        do {
            try await RSVPService.shared.setRSVP(
                gameId: gameId,
                userId: user.id!,
                userName: user.displayName,
                status: status
            )
            await fetchRSVPs()
            await fetchUserRSVP()
        } catch {
            print("Error RSVPing: \(error)")
        }
        isLoading = false
    }
    
    func removeRSVP() async {
        guard let gameId = game.id,
              let userId = authViewModel.currentUser?.id else { return }
        
        isLoading = true
        do {
            try await RSVPService.shared.removeRSVP(gameId: gameId, userId: userId)
            await fetchRSVPs()
            await fetchUserRSVP()
        } catch {
            print("Error removing RSVP: \(error)")
        }
        isLoading = false
    }
    
    func deleteGame() async {
        guard let gameId = game.id else { return }
        do {
            try await GameService.shared.deleteGame(gameId: gameId)
            dismiss()
        } catch {
            print("Error deleting game: \(error)")
        }
    }
}
