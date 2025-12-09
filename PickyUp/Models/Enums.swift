//Enums

import Foundation

enum SportType: String, Codable, CaseIterable {
    case soccer = "Soccer"
    case basketball = "Basketball"
    case volleyball = "Volleyball"
    case tennis = "Tennis"
    case football = "Football"
    case pickleball = "Pickleball"
    case other = "Other"
    
    // Emoji (kept for any textual contexts where you prefer emoji)
    var icon: String {
        switch self {
        case .soccer: return "⚽️"
        case .basketball: return "🏀"
        case .volleyball: return "🏐"
        case .tennis: return "🎾"
        case .football: return "🏈"
        case .pickleball: return "🏓"
        case .other: return "🏅"
        }
    }
    
    // Legacy unfilled system icon (kept for backward compatibility if referenced anywhere)
    var systemIcon: String {
        switch self {
        case .soccer: return "soccerball"
        case .basketball: return "basketball"
        case .volleyball: return "volleyball"
        case .tennis: return "tennisball"
        case .football: return "football"
        case .pickleball: return "pickleball"
        case .other: return "sportscourt"
        }
    }
    
    // New single source of truth for map/detail pins
    var filledSystemIcon: String {
        switch self {
        case .soccer: return "figure.soccer"         // no soccerball.fill available
        case .basketball: return "basketball.fill"
        case .volleyball: return "volleyball.fill"
        case .tennis: return "tennisball.fill"
        case .football: return "football.fill"
        case .pickleball: return "figure.pickleball"
        case .other: return "mappin.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .soccer: return "green"
        case .basketball: return "orange"
        case .volleyball: return "blue"
        case .tennis: return "yellow"
        case .football: return "red"
        case .pickleball: return "pink"
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

// Legacy single-axis sort (kept for backward compatibility)
enum SortOption: String, CaseIterable {
    case nearest = "Closest"
    case farthest = "Farthest"
    case mostAttendees = "Highest"
    case leastAttendees = "Lowest"
}

// New, cleaner multi-axis sorting
enum DistanceSortOption: String, CaseIterable {
    case nearest = "Closest"
    case farthest = "Farthest"
}

enum AttendeesSortOption: String, CaseIterable {
    case most = "Most"
    case least = "Least"
}

enum DateSortOption: String, CaseIterable {
    case soonest = "Soonest"
    case latest = "Latest"
}

