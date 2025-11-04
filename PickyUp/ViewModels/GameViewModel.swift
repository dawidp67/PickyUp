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
    @Published var selectedSortOption: SortOption?
    @Published var userLocation: CLLocationCoordinate2D?
    
    private let gameService = GameService.shared
    private var gamesListener: ListenerRegistration?
    
    init() {
        setupGamesListener()
    }
    
    deinit {
        gamesListener?.remove()
    }
    
    private func setupGamesListener() {
        gamesListener = gameService.listenToGames { [weak self] games in
            self?.games = games
            self?.applyFilters()
        }
    }
    
    func applyFilters() {
        var result = games
        
        // Filter by sport
        if let sport = selectedSportFilter {
            result = result.filter { $0.sportType == sport }
        }
        
        // Sort
        if let sort = selectedSortOption {
            switch sort {
            case .nearest, .farthest:
                if let userLoc = userLocation {
                    result = result.sorted { game1, game2 in
                        let dist1 = distance(from: userLoc, to: game1.location.coordinate)
                        let dist2 = distance(from: userLoc, to: game2.location.coordinate)
                        return sort == .nearest ? dist1 < dist2 : dist1 > dist2
                    }
                }
            case .mostAttendees, .leastAttendees:
                // Will be implemented when we fetch attendee counts
                break
            }
        }
        
        filteredGames = result
    }
    
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
    
    func clearFilters() {
        selectedSportFilter = nil
        selectedSortOption = nil
        applyFilters()
    }
    
    func createGame(
        sportType: SportType,
        customSportName: String?,
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
