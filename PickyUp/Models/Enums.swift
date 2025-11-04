import Foundation

enum SportType: String, Codable, CaseIterable {
    case soccer = "Soccer"
    case basketball = "Basketball"
    
    var icon: String {
        switch self {
        case .soccer: return "⚽️"
        case .basketball: return "🏀"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .soccer: return "soccerball"
        case .basketball: return "basketball"
        }
    }
}

enum GameStatus: String, Codable {
    case active = "Active"
    case cancelled = "Cancelled"
    case completed = "Completed"
}

enum RSVPStatus: String, Codable {
    case going = "Going"
    case maybe = "Maybe"
    
    var color: String {
        switch self {
        case .going: return "green"
        case .maybe: return "orange"
        }
    }
}
