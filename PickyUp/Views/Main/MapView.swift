//
//  MapView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI
import MapKit

struct MapTabView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.00902),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var games: [Game] = []
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: games) { game in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: game.location.latitude,
                                                             longitude: game.location.longitude)) {
                MapAnnotationView(game: game)
            }
        }
        .onAppear {
            Task {
                games = try await GameService.shared.fetchUpcomingGames()
            }
        }
    }
}
