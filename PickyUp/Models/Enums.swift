//Enums

import Foundation

enum SportType: String, Codable, CaseIterable {
    case soccer = "Soccer"
    case basketball = "Basketball"
    case volleyball = "Volleyball"
    case tennis = "Tennis"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .soccer: return "⚽️"
        case .basketball: return "🏀"
        case .volleyball: return "🏐"
        case .tennis: return "🎾"
        case .other: return "⚾️"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .soccer: return "soccerball"
        case .basketball: return "basketball"
        case .volleyball: return "volleyball"
        case .tennis: return "tennisball"
        case .other: return "sportscourt"
        }
    }
    
    var color: String {
        switch self {
        case .soccer: return "green"
        case .basketball: return "orange"
        case .volleyball: return "blue"
        case .tennis: return "yellow"
        case .other: return "purple"
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

enum SortOption: String, CaseIterable {
    case nearest = "Closest"
    case farthest = "Farthest"
    case mostAttendees = "Highest"
    case leastAttendees = "Lowest"
}
