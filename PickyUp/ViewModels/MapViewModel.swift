//
// MapViewModel.swift
//
// ViewModels/MapViewModel.swift
//
// Last Updated 11/3/25

import Foundation
import SwiftUI
import MapKit
import Combine

@MainActor
class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var selectedGame: Game?
    @Published var showMapFullScreen = false
    
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    private var lastUpdateTime: Date = .distantPast
    private let updateThrottle: TimeInterval = 2.0 // Only update every 2 seconds
    
    init() {
        setupLocationObserver()
    }
    
    private func setupLocationObserver() {
        // Observe location changes with throttle to prevent rapid updates
        locationService.$userLocation
            .compactMap { $0 }
            .removeDuplicates { coord1, coord2 in
                // Only update if moved more than ~10 meters
                let distance = self.calculateDistance(from: coord1, to: coord2)
                return distance < 10
            }
            .sink { [weak self] location in
                guard let self = self else { return }
                let now = Date()
                // Throttle updates to prevent multiple per frame
                if now.timeIntervalSince(self.lastUpdateTime) > self.updateThrottle {
                    self.lastUpdateTime = now
                    self.centerOnLocation(location, animated: false)
                }
            }
            .store(in: &cancellables)
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    func centerOnLocation(_ coordinate: CLLocationCoordinate2D, animated: Bool = true) {
        let newRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        if animated {
            withAnimation {
                region = newRegion
            }
        } else {
            region = newRegion
        }
    }
    
    func centerOnUserLocation() {
        if let userLocation = locationService.userLocation {
            centerOnLocation(userLocation, animated: true)
        } else {
            // Request location if we don't have it yet
            locationService.requestLocation()
        }
    }
}
