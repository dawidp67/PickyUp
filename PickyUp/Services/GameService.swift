//GameService

import Foundation
import FirebaseFirestore

class GameService {
    static let shared = GameService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func createGame(_ game: Game) async throws -> String {
        var gameData = game
        gameData.createdAt = Date()
        gameData.updatedAt = Date()
        gameData.status = .active
        
        let docRef = try db.collection("games").addDocument(from: gameData)
        return docRef.documentID
    }
    
    func fetchUpcomingGames() async throws -> [Game] {
        let snapshot = try await db.collection("games")
            .whereField("status", isEqualTo: GameStatus.active.rawValue)
            .whereField("dateTime", isGreaterThan: Date())
            .order(by: "dateTime")
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Game.self) }
    }
    
    func fetchUserCreatedGames(userId: String) async throws -> [Game] {
        let snapshot = try await db.collection("games")
            .whereField("creatorId", isEqualTo: userId)
            .order(by: "dateTime", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Game.self) }
    }
    
    func fetchGame(gameId: String) async throws -> Game {
        let document = try await db.collection("games").document(gameId).getDocument()
        guard let game = try? document.data(as: Game.self) else {
            throw NSError(domain: "GameService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Game not found"])
        }
        return game
    }
    
    func updateGame(gameId: String, updates: [String: Any]) async throws {
        var updateData = updates
        updateData["updatedAt"] = Timestamp(date: Date())
        try await db.collection("games").document(gameId).updateData(updateData)
    }
    
    func deleteGame(gameId: String) async throws {
        let rsvps = try await db.collection("rsvps")
            .whereField("gameId", isEqualTo: gameId)
            .getDocuments()
        
        let batch = db.batch()
        rsvps.documents.forEach { batch.deleteDocument($0.reference) }
        batch.deleteDocument(db.collection("games").document(gameId))
        
        try await batch.commit()
    }
    
    func listenToGames(completion: @escaping ([Game]) -> Void) -> ListenerRegistration {
        return db.collection("games")
            .whereField("status", isEqualTo: GameStatus.active.rawValue)
            .whereField("dateTime", isGreaterThan: Date())
            .order(by: "dateTime")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching games: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                let games = documents.compactMap { try? $0.data(as: Game.self) }
                completion(games)
            }
    }
    
    func fetchGameAttendeeCount(gameId: String) async throws -> (going: Int, maybe: Int) {
        let snapshot = try await db.collection("rsvps")
            .whereField("gameId", isEqualTo: gameId)
            .getDocuments()
        
        let rsvps = try snapshot.documents.compactMap { try $0.data(as: RSVP.self) }
        let going = rsvps.filter { $0.status == .going }.count
        let maybe = rsvps.filter { $0.status == .maybe }.count
        
        return (going, maybe)
    }
}
