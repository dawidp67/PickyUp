//User

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var profilePhotoURL: String?
    var createdAt: Date
    
    // Computed property for display
    var initials: String {
        let names = displayName.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1) + names[1].prefix(1)).uppercased()
        } else if let first = names.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}
