//LocationService

import Foundation
import CoreLocation
import MapKit

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        
        print("🗺️ LocationService initialized")
        checkLocationAuthorization()
    }
    
    func requestLocation() {
        print("🗺️ Requesting location permission...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func checkLocationAuthorization() {
        authorizationStatus = locationManager.authorizationStatus
        
        print("🗺️ Current authorization status: \(authorizationStatus?.rawValue ?? -1)")
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("🗺️ Location not determined - requesting permission")
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("⚠️ Location restricted")
        case .denied:
            print("⚠️ Location denied")
        case .authorizedAlways, .authorizedWhenInUse:
            print("✅ Location authorized - starting updates")
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func geocodeAddress(_ address: String) async throws -> GameLocation {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        
        guard let placemark = placemarks.first,
              let location = placemark.location else {
            throw NSError(domain: "LocationService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Could not find location"])
        }
        
        return GameLocation(
            address: address,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            placeName: placemark.name
        )
    }
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> GameLocation {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            throw NSError(domain: "LocationService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Could not find address"])
        }
        
        let address = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode
        ].compactMap { $0 }.joined(separator: ", ")
        
        return GameLocation(
            address: address,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            placeName: placemark.name
        )
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("🔄 Authorization changed to: \(manager.authorizationStatus.rawValue)")
        authorizationStatus = manager.authorizationStatus
        checkLocationAuthorization()
    }
}
