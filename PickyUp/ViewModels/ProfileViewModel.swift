import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var attendingGames: [Game] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let rsvpService = RSVPService.shared
    private let gameService = GameService.shared
    
    func fetchAttendingGames(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch user's RSVPs
            let rsvps = try await rsvpService.fetchUserRSVPs(userId: userId)
            
            // Filter for accepted/going RSVPs
            let gameIds = rsvps
                .filter { $0.status == .going }
                .compactMap { $0.gameId }
            
            // Fetch the actual games
            var games: [Game] = []
            for gameId in gameIds {
                if let game = try? await gameService.fetchGame(gameId: gameId) {
                    games.append(game)
                }
            }
            
            attendingGames = games
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching attending games: \(error)")
        }
        
        isLoading = false
    }
}
