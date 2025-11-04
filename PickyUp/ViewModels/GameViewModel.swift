import Foundation
import FirebaseFirestore

@MainActor
class GameViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var userCreatedGames: [Game] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
        }
    }
    
    func createGame(
        sportType: SportType,
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
    
    func updateGame(gameId: String, updates: [String: Any]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await gameService.updateGame(gameId: gameId, updates: updates)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
