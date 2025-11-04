//ProfileViewModel

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
            let rsvps = try await rsvpService.fetchUserRSVPs(userId: userId)
            
            let gameIds = rsvps
                .filter { $0.status == .going }
                .compactMap { $0.gameId }
            
            var games: [Game] = []
            for gameId in gameIds {
                if let game = try? await gameService.fetchGame(gameId: gameId), game.isUpcoming {
                    games.append(game)
                }
            }
            
            attendingGames = games.sorted { $0.dateTime < $1.dateTime }
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching attending games: \(error)")
        }
        
        isLoading = false
    }
}
