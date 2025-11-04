import Foundation
import SwiftUI

struct Constants {
    struct Firestore {
        static let usersCollection = "users"
        static let gamesCollection = "games"
        static let rsvpsCollection = "rsvps"
    }
    
    struct UI {
        static let cornerRadius: CGFloat = 10
        static let padding: CGFloat = 16
    }
    
    struct Colors {
        static let primaryColor = Color.blue
        static let secondaryColor = Color.gray
    }
}
