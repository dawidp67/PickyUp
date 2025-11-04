//
//  Helpers.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import Foundation
import CoreLocation

struct Validators {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}

class Helpers {
    static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: date)
    }
    
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    static func calculateDistance(from: (lat: Double, lon: Double), to: (lat: Double, lon: Double)) -> Double {
        let fromLocation = CLLocation(latitude: from.lat, longitude: from.lon)
        let toLocation = CLLocation(latitude: to.lat, longitude: to.lon)
        return fromLocation.distance(from: toLocation)
    }
}
