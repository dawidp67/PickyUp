//MapViewModel

import Foundation
import MapKit

@MainActor
class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var selectedGame: Game?
    @Published var showMapFullScreen = false
    
    private let locationService = LocationService.shared
    
    init() {
        setupLocationObserver()
    }
    
    private func setupLocationObserver() {
        if let userLocation = locationService.userLocation {
            centerOnLocation(userLocation)
        }
    }
    
    func centerOnLocation(_ coordinate: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
    
    func centerOnUserLocation() {
        if let userLocation = locationService.userLocation {
            centerOnLocation(userLocation)
        } else {
            locationService.requestLocation()
        }
    }
}
