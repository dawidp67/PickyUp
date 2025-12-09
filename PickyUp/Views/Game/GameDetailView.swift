//
//  GameDetailView.swift (Updated with unified game pin style and user-centered button)
//  PickyUp
//

import SwiftUI
import MapKit
import FirebaseFirestore
import CoreLocation

struct GameDetailView: View {
    let game: Game
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Live-updating state
    @State private var liveGame: Game?
    @State private var rsvps: [RSVP] = []
    @State private var userRSVP: RSVP?
    
    // Listeners
    @State private var gameListener: ListenerRegistration?
    @State private var rsvpListener: ListenerRegistration?
    
    @State private var isLoading = false
    @State private var showingDeleteAlert = false
    @State private var showingEditGame = false
    @State private var selectedUser: User?
    
    // Full-screen map
    @State private var showFullMap = false
    
    var currentGame: Game { liveGame ?? game }
    
    var isCreator: Bool {
        currentGame.creatorId == authViewModel.currentUser?.id
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
            .refreshable {
                await manualRefresh()
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
                EditGameView(game: currentGame)
            }
            .sheet(item: $selectedUser) { user in
                UserProfileView(user: user)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showFullMap) {
                GameFullMapView(game: currentGame)
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
                startListeners()
                await fetchUserRSVP()
            }
            .onDisappear {
                stopListeners()
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
            
            if let description = currentGame.description, !description.isEmpty {
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
                // Unified icon in header
                Image(systemName: currentGame.sportType.filledSystemIcon)
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading) {
                    Text(currentGame.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Button {
                        Task {
                            await loadUser(userId: currentGame.creatorId)
                        }
                    } label: {
                        Text("by \(currentGame.creatorName)")
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
                    Text(currentGame.dateTime.relativeDateString)
                        .font(.headline)
                    Text(currentGame.dateTime.timeString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
            }
            
            Label {
                Text("\(currentGame.duration) minutes")
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
            
            Text(currentGame.location.address)
                .font(.subheadline)
            
            // Tappable embedded map with unified game pin using sport icon
            ZStack {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: currentGame.location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [currentGame]) { game in
                    MapAnnotation(coordinate: game.location.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: game.sportType.filledSystemIcon)
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.blue)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .accessibilityLabel("Game location pin")
                    }
                }
                .frame(height: 200)
                .cornerRadius(12)
                
                Rectangle()
                    .foregroundStyle(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showFullMap = true
                    }
            }
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
    
    // MARK: - Live updates and refresh
    
    private func startListeners() {
        guard let gameId = currentGame.id else { return }
        gameListener?.remove()
        gameListener = GameService.shared.listenToGame(gameId: gameId) { updated in
            if let updated = updated {
                Task { @MainActor in
                    self.liveGame = updated
                }
            }
        }
        rsvpListener?.remove()
        rsvpListener = RSVPService.shared.listenToRSVPs(gameId: gameId) { rsvps in
            Task { @MainActor in
                self.rsvps = rsvps
            }
        }
    }
    
    private func stopListeners() {
        gameListener?.remove()
        gameListener = nil
        rsvpListener?.remove()
        rsvpListener = nil
    }
    
    private func manualRefresh() async {
        guard let gameId = currentGame.id else { return }
        do {
            let latest = try await GameService.shared.fetchGame(gameId: gameId)
            await MainActor.run {
                self.liveGame = latest
            }
        } catch {
            // ignore
        }
        await fetchUserRSVP()
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
    
    func fetchUserRSVP() async {
        guard let gameId = currentGame.id,
              let userId = authViewModel.currentUser?.id else { return }
        do {
            userRSVP = try await RSVPService.shared.fetchUserRSVP(gameId: gameId, userId: userId)
        } catch {
            print("Error fetching user RSVP: \(error)")
        }
    }
    
    func rsvpToGame(status: RSVPStatus) async {
        guard let gameId = currentGame.id,
              let user = authViewModel.currentUser else { return }
        
        isLoading = true
        do {
            try await RSVPService.shared.setRSVP(
                gameId: gameId,
                userId: user.id!,
                userName: user.displayName,
                status: status
            )
            await fetchUserRSVP()
        } catch {
            print("Error RSVPing: \(error)")
        }
        isLoading = false
    }
    
    func removeRSVP() async {
        guard let gameId = currentGame.id,
              let userId = authViewModel.currentUser?.id else { return }
        
        isLoading = true
        do {
            try await RSVPService.shared.removeRSVP(gameId: gameId, userId: userId)
            await fetchUserRSVP()
        } catch {
            print("Error removing RSVP: \(error)")
        }
        isLoading = false
    }
    
    func deleteGame() async {
        guard let gameId = currentGame.id else { return }
        do {
            try await GameService.shared.deleteGame(gameId: gameId)
            dismiss()
        } catch {
            print("Error deleting game: \(error)")
        }
    }
}

// MARK: - Full-Screen Map View

struct GameFullMapView: View {
    let game: Game
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationService = LocationService.shared
    
    @State private var region: MKCoordinateRegion
    
    init(game: Game) {
        self.game = game
        _region = State(initialValue: MKCoordinateRegion(
            center: game.location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region,
                    interactionModes: .all,
                    showsUserLocation: true,
                    annotationItems: [game]) { item in
                    MapAnnotation(coordinate: item.location.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: item.sportType.filledSystemIcon)
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.blue)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .accessibilityLabel("Game location pin")
                    }
                }
                .ignoresSafeArea()
                
                // Single floating location button (bottom trailing) — centers on USER location, sized like MapView
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            centerOnUser()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                        .accessibilityLabel("Center on your location")
                    }
                }
            }
            .navigationTitle("Game Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .accessibilityLabel("Close")
                }
            }
            .onAppear {
                // Do not auto-center on game; leave as-is. User can center on themselves with the button.
            }
        }
    }
    
    private func centerOnUser() {
        if let userLoc = locationService.userLocation {
            withAnimation {
                region = MKCoordinateRegion(
                    center: userLoc,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            }
        } else {
            locationService.requestLocation()
        }
    }
    
    // These helpers remain available if needed elsewhere
    private func centerOnGame() {
        withAnimation {
            region.center = game.location.coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }
    }
    
    private func regionThatFits(points: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = points.first else {
            return MKCoordinateRegion(center: game.location.coordinate,
                                      span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        }
        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude
        
        for p in points.dropFirst() {
            minLat = min(minLat, p.latitude)
            maxLat = max(maxLat, p.latitude)
            minLon = min(minLon, p.longitude)
            maxLon = max(maxLon, p.longitude)
        }
        
        let pad: CLLocationDegrees = 0.2
        var spanLat = (maxLat - minLat) * (1.0 + pad)
        var spanLon = (maxLon - minLon) * (1.0 + pad)
        spanLat = max(spanLat, 0.01)
        spanLon = max(spanLon, 0.01)
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        return MKCoordinateRegion(center: center,
                                  span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon))
    }
}

