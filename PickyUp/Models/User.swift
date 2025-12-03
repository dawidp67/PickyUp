//
// User.swift
// Models/User.swift
//
// Unified user model for the entire app
// Last Updated: 12/2/25

import Foundation
import FirebaseFirestore
import Cloudinary

struct User: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var profilePhotoURL: String?
    var bio: String?
    var createdAt: Date?
    var updatedAt: Date?
    
    // For search functionality (if you're using it)
    var searchTokens: [String]?
    
    // Derive initials from displayName
    var initials: String {
        let names = displayName.split(separator: " ")
        if names.count >= 2 {
            // First letter of first name + first letter of last name
            return String(names[0].prefix(1) + names[1].prefix(1)).uppercased()
        } else if let first = names.first {
            // If only one name, use first two letters
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}

// Type alias for backward compatibility if needed
typealias AppUser = User
