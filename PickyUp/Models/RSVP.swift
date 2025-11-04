import Foundation
import FirebaseFirestore

struct RSVP: Codable, Identifiable {
    @DocumentID var id: String?
    var gameId: String
    var userId: String
    var userName: String
    var status: RSVPStatus
    var createdAt: Date
    var updatedAt: Date
}
