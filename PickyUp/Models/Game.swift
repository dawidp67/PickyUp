import Foundation
import FirebaseFirestore
import CoreLocation

struct GameLocation: Codable, Hashable {
    var address: String
    var latitude: Double
    var longitude: Double
    var placeName: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Game: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var creatorId: String
    var creatorName: String
    var sportType: SportType
    var location: GameLocation
    var dateTime: Date
    var duration: Int // in minutes
    var description: String?
    var status: GameStatus
    var createdAt: Date
    var updatedAt: Date
    
    // Computed properties
    var isUpcoming: Bool {
        dateTime > Date()
    }
    
    var isPast: Bool {
        dateTime.addingTimeInterval(TimeInterval(duration * 60)) < Date()
    }
    
    var endTime: Date {
        dateTime.addingTimeInterval(TimeInterval(duration * 60))
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.id == rhs.id
    }
}
