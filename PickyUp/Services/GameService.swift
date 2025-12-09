//
// GameService.swift
//
// Services/GameService.swift
//
// Last Updated 11/16/25

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
    func fetchGamesCreatedBy(userId: String) async throws -> [Game] {
        let snapshot = try await db.collection("games")
            .whereField("creatorId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Game.self)
        }
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
        
        // Notify all RSVPed users about the game update
        do {
            let game = try await fetchGame(gameId: gameId)
            let rsvps = try await RSVPService.shared.fetchRSVPs(gameId: gameId)
            
            for rsvp in rsvps where rsvp.userId != game.creatorId {
                try await NotificationService.shared.createNotification(
                    userId: rsvp.userId,
                    type: .gameUpdate,
                    title: "Game Updated",
                    message: "A game you're attending has been updated",
                    fromUserId: game.creatorId,
                    gameId: gameId
                )
            }
            print("✅ Game update notifications sent to \(rsvps.count) attendees")
        } catch {
            print("⚠️ Failed to create game update notifications: \(error.localizedDescription)")
        }
    }
    
    func deleteGame(gameId: String) async throws {
        // First, get the game details and all RSVPs
        let game = try await fetchGame(gameId: gameId)
        let rsvps = try await db.collection("rsvps")
            .whereField("gameId", isEqualTo: gameId)
            .getDocuments()
        
        // Notify all users who RSVPed to the game
        for rsvpDoc in rsvps.documents {
            if let rsvp = try? rsvpDoc.data(as: RSVP.self),
               rsvp.userId != game.creatorId {
                do {
                    let sportName = game.sportType == .other ? (game.customSportName ?? "Game") : game.sportType.rawValue
                    try await NotificationService.shared.createNotification(
                        userId: rsvp.userId,
                        type: .gameUpdate,
                        title: "Game Cancelled",
                        message: "\(game.creatorName) cancelled the \(sportName) game",
                        fromUserId: game.creatorId,
                        gameId: gameId
                    )
                } catch {
                    print("⚠️ Failed to notify user \(rsvp.userId): \(error.localizedDescription)")
                }
            }
        }
        print("✅ Game cancellation notifications sent")
        
        // Delete all RSVPs and the game
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
    
    // NEW: Live listener for a single game
    func listenToGame(gameId: String, completion: @escaping (Game?) -> Void) -> ListenerRegistration {
        return db.collection("games").document(gameId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to game \(gameId): \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                guard let snapshot = snapshot else {
                    completion(nil)
                    return
                }
                let game = try? snapshot.data(as: Game.self)
                completion(game)
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

