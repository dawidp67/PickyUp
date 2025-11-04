import SwiftUI
import MapKit

struct GameMapPin: Identifiable {
    let id = UUID()
    let game: Game
    
    var coordinate: CLLocationCoordinate2D {
        game.location.coordinate
    }
}

struct MapView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedGame: Game? // 👈 used for sheet
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(coordinateRegion: $region, annotationItems: gamePins) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    VStack(spacing: 4) {
                        Image(systemName: "sportscourt.fill")
                            .foregroundColor(.blue)
                            .font(.title)
                            .background(Circle().fill(Color.white).frame(width: 40, height: 40))
                            .shadow(radius: 3)
                        Text(pin.game.displaySportName)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    // 👇 attach tap gesture to the *view*, not pin
                    .onTapGesture {
                        selectedGame = pin.game
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            Button(action: centerOnUserLocation) {
                Image(systemName: "location.circle.fill")
                    .font(.title)
                    .padding()
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 3)
                    .padding()
            }
        }
        .sheet(item: $selectedGame) { game in
            GameDetailView(game: game)
                .environmentObject(gameViewModel)
        }
    }
    
    private var gamePins: [GameMapPin] {
        gameViewModel.games.map { GameMapPin(game: $0) }
    }
    
    private func centerOnUserLocation() {
        // Later: connect to CLLocationManager
        print("Centering on user location...")
    }
}
