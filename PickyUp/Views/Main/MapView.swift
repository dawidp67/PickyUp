//
// MapView.swift
//
// Views/Main/MapView.swift
//
// Last Updated 11/4/25
import SwiftUI
import MapKit

struct GameMapPin: Identifiable {
    let id = UUID()
    let game: Game
    
    var coordinate: CLLocationCoordinate2D {
        game.location.coordinate
    }
    
    var iconName: String {
        switch game.sportType {
        case .soccer:
            return "figure.soccer"  // Changed from "soccerball"
        case .basketball:
            return "basketball.fill"
        case .volleyball:
            return "volleyball.fill"
        case .tennis:
            return "tennisball.fill"
        case .football:
            return "football.fill"
        case .pickleball:
            return "figure.pickleball"
        case .other:
            return "mappin.circle.fill"
        }
    }
    
    var displayName: String {
        // Fallback to sport type if displaySportName is empty
        if game.displaySportName.isEmpty {
            return game.sportType.rawValue
        }
        return game.displaySportName
    }
}

struct MapView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var locationService = LocationService.shared
    
    @State private var selectedGame: Game?
    @State private var showingCreateGame = false
    @State private var hasInitializedLocation = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(coordinateRegion: $mapViewModel.region,
                showsUserLocation: true,
                annotationItems: gamePins) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    VStack(spacing: 4) {
                        Image(systemName: pin.iconName)
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.blue)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Text(pin.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.black)  // ✅ Fixed: Changed to .black
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                            )
                    }
                    .onTapGesture {
                        selectedGame = pin.game
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            // Button Stack
            VStack(spacing: 12) {
                // Create Game Button
                Button(action: {
                    showingCreateGame = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                // Center Location Button
                Button(action: {
                    mapViewModel.centerOnUserLocation()
                }) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
        .sheet(item: $selectedGame) { game in
            GameDetailView(game: game)
                .environmentObject(gameViewModel)
        }
        .sheet(isPresented: $showingCreateGame) {
            CreateGameView()
                .environmentObject(gameViewModel)
        }
        .onAppear {
            // Request location permission if not already granted
            if locationService.authorizationStatus == .notDetermined {
                locationService.requestLocation()
            }
            // Center on user location when view appears (only once)
            if !hasInitializedLocation, let userLocation = locationService.userLocation {
                DispatchQueue.main.async {
                    mapViewModel.centerOnLocation(userLocation)
                    hasInitializedLocation = true
                }
            }
        }
    }
    
    private var gamePins: [GameMapPin] {
        gameViewModel.games.map { GameMapPin(game: $0) }
    }
}
