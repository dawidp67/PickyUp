//GameViewModel

import Foundation
import FirebaseFirestore
import CoreLocation

@MainActor
class GameViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var filteredGames: [Game] = []
    @Published var userCreatedGames: [Game] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filter options
    @Published var selectedSportFilter: SportType?
    
    // Multi-axis sorting
    @Published var selectedDateSort: DateSortOption? {
        didSet { applyFilters() }
    }
    @Published var selectedDistanceSort: DistanceSortOption? {
        didSet { applyFilters() }
    }
    @Published var selectedAttendeesSort: AttendeesSortOption? {
        didSet { applyFilters() }
    }
    
    // Legacy single sort (kept to avoid breaking call sites)
    @Published var selectedSortOption: SortOption? {
        didSet {
            mapLegacySortToNewOptions()
            applyFilters()
        }
    }
    
    @Published var userLocation: CLLocationCoordinate2D? {
        didSet {
            applyFilters()
        }
    }
    
    // Cache of attendee counts (going only) by gameId
    @Published private(set) var attendeeCountCache: [String: Int] = [:]
    private var attendeeCountTasks: [String: Task<Void, Never>] = [:]
    
    private let gameService = GameService.shared
    private var gamesListener: ListenerRegistration?
    
    init() {
        setupGamesListener()
    }
    
    deinit {
        gamesListener?.remove()
        attendeeCountTasks.values.forEach { $0.cancel() }
    }
    
    private func setupGamesListener() {
        gamesListener = gameService.listenToGames { [weak self] games in
            Task { @MainActor in
                self?.games = games
                self?.applyFilters()
                self?.prefetchAttendeeCounts(for: games)
            }
        }
    }
    
    func applyFilters() {
        var result = games
        
        // Filter by sport
        if let sport = selectedSportFilter {
            result = result.filter { $0.sportType == sport }
        }
        
        // Multi-key comparator: Date -> Distance -> Attendees
        if selectedDateSort != nil || selectedDistanceSort != nil || selectedAttendeesSort != nil {
            let datePref = selectedDateSort
            let distPref = selectedDistanceSort
            let attPref = selectedAttendeesSort
            let userLoc = userLocation
            
            result = result.sorted { g1, g2 in
                if let datePref {
                    let d1 = g1.dateTime
                    let d2 = g2.dateTime
                    if d1 != d2 {
                        return datePref == .soonest ? d1 < d2 : d1 > d2
                    }
                }
                if let distPref, let userLoc {
                    let d1 = distance(from: userLoc, to: g1.location.coordinate)
                    let d2 = distance(from: userLoc, to: g2.location.coordinate)
                    if d1 != d2 {
                        return distPref == .nearest ? d1 < d2 : d1 > d2
                    }
                }
                if let attPref {
                    let c1 = attendeeCount(for: g1)
                    let c2 = attendeeCount(for: g2)
                    if c1 != c2 {
                        return attPref == .most ? c1 > c2 : c1 < c2
                    }
                }
                return g1.dateTime < g2.dateTime
            }
        }
        
        filteredGames = result
        prefetchAttendeeCounts(for: result)
    }
    
    private func attendeeCount(for game: Game) -> Int {
        guard let id = game.id else { return 0 }
        return attendeeCountCache[id] ?? 0
    }
    
    private func prefetchAttendeeCounts(for games: [Game]) {
        for game in games {
            guard let id = game.id, attendeeCountCache[id] == nil, attendeeCountTasks[id] == nil else { continue }
            let t = Task { [weak self] in
                do {
                    let counts = try await GameService.shared.fetchGameAttendeeCount(gameId: id)
                    await MainActor.run {
                        // Use going count; switch to counts.going + counts.maybe if desired
                        self?.attendeeCountCache[id] = counts.going
                        self?.applyFilters()
                    }
                } catch {
                    // Ignore failures; default 0
                }
                await MainActor.run {
                    self?.attendeeCountTasks[id] = nil
                }
            }
            attendeeCountTasks[id] = t
        }
    }
    
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
    
    func clearFilters() {
        selectedSportFilter = nil
        selectedSortOption = nil
        selectedDateSort = nil
        selectedDistanceSort = nil
        selectedAttendeesSort = nil
        applyFilters()
    }
    
    private func mapLegacySortToNewOptions() {
        guard let legacy = selectedSortOption else { return }
        switch legacy {
        case .nearest:
            selectedDistanceSort = .nearest
        case .farthest:
            selectedDistanceSort = .farthest
        case .mostAttendees:
            selectedAttendeesSort = .most
        case .leastAttendees:
            selectedAttendeesSort = .least
        }
    }
    
    func createGame(
        sportType: SportType,
        customSportName: String?,
        gameTitle: String?,                 // ADDED
        location: GameLocation,
        dateTime: Date,
        duration: Int,
        description: String?,
        creatorId: String,
        creatorName: String
    ) async {
        isLoading = true
        errorMessage = nil
        
        let game = Game(
            creatorId: creatorId,
            creatorName: creatorName,
            sportType: sportType,
            customSportName: sportType == .other ? customSportName : nil,
            gameTitle: gameTitle,            // ADDED
            location: location,
            dateTime: dateTime,
            duration: duration,
            description: description,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            _ = try await gameService.createGame(game)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateGame(gameId: String, location: GameLocation?, dateTime: Date?, duration: Int?) async {
        isLoading = true
        errorMessage = nil
        
        var updates: [String: Any] = [:]
        
        if let location = location {
            updates["location"] = [
                "address": location.address,
                "latitude": location.latitude,
                "longitude": location.longitude,
                "placeName": location.placeName as Any
            ]
        }
        
        if let dateTime = dateTime {
            updates["dateTime"] = Timestamp(date: dateTime)
        }
        
        if let duration = duration {
            updates["duration"] = duration
        }
        
        do {
            try await gameService.updateGame(gameId: gameId, updates: updates)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func fetchUserCreatedGames(userId: String) async {
        do {
            userCreatedGames = try await gameService.fetchUserCreatedGames(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteGame(gameId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await gameService.deleteGame(gameId: gameId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

