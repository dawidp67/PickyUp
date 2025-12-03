//
// RSVPService.swift
//
// Services/RSVPService.swift
//
// Last Updated 11/16/25

import Foundation
import FirebaseFirestore

class RSVPService {
    static let shared = RSVPService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func setRSVP(gameId: String, userId: String, userName: String, status: RSVPStatus) async throws {
        let existingRSVPs = try await db.collection("rsvps")
            .whereField("gameId", isEqualTo: gameId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        if let existingDoc = existingRSVPs.documents.first {
            try await existingDoc.reference.updateData([
                "status": status.rawValue,
                "updatedAt": Timestamp(date: Date())
            ])
        } else {
            let rsvp = RSVP(
                gameId: gameId,
                userId: userId,
                userName: userName,
                status: status,
                createdAt: Date(),
                updatedAt: Date()
            )
            try db.collection("rsvps").addDocument(from: rsvp)
        }
        
        // Send notification to game creator
        do {
            let game = try await GameService.shared.fetchGame(gameId: gameId)
            
            // Don't notify the creator if they're the one RSVPing
            if game.creatorId != userId {
                let statusText = status == .going ? "is going" : "might attend"
                try await NotificationService.shared.createNotification(
                    userId: game.creatorId,
                    type: .gameUpdate,
                    title: "Game RSVP",
                    message: "\(userName) \(statusText) to your game",
                    fromUserId: userId,
                    gameId: gameId
                )
                print("✅ RSVP notification sent to game creator")
            }
        } catch {
            print("⚠️ Failed to create RSVP notification: \(error.localizedDescription)")
        }
    }
    
    func removeRSVP(gameId: String, userId: String) async throws {
        let snapshot = try await db.collection("rsvps")
            .whereField("gameId", isEqualTo: gameId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }
    
    func fetchRSVPs(gameId: String) async throws -> [RSVP] {
        let snapshot = try await db.collection("rsvps")
            .whereField("gameId", isEqualTo: gameId)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: RSVP.self) }
    }
    
    func fetchUserRSVP(gameId: String, userId: String) async throws -> RSVP? {
        let snapshot = try await db.collection("rsvps")
            .whereField("gameId", isEqualTo: gameId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return try snapshot.documents.first?.data(as: RSVP.self)
    }
    
    func fetchUserRSVPs(userId: String) async throws -> [RSVP] {
        let snapshot = try await db.collection("rsvps")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: RSVP.self) }
    }
    
    func listenToRSVPs(gameId: String, completion: @escaping ([RSVP]) -> Void) -> ListenerRegistration {
        return db.collection("rsvps")
            .whereField("gameId", isEqualTo: gameId)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching RSVPs: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                let rsvps = documents.compactMap { try? $0.data(as: RSVP.self) }
                completion(rsvps)
            }
    }
}
