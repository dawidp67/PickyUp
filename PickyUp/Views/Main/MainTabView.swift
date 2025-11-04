import SwiftUI
import MapKit

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var mapViewModel = MapViewModel()
    @State private var showMapFullScreen = false
    @State private var hasShownMapPrompt = false
    
    var body: some View {
        ZStack {
            TabView {
                MapTabView()
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                    .environmentObject(gameViewModel)
                    .environmentObject(mapViewModel)
                
                GameListView()
                    .tabItem {
                        Label("Games", systemImage: "list.bullet")
                    }
                    .environmentObject(gameViewModel)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .environmentObject(authViewModel)
                    .environmentObject(gameViewModel)
            }
            
            if showMapFullScreen {
                FullScreenMapView(showMapFullScreen: $showMapFullScreen)
                    .environmentObject(gameViewModel)
                    .environmentObject(mapViewModel)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .onAppear {
            if !hasShownMapPrompt {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showMapFullScreen = true
                    hasShownMapPrompt = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            showMapFullScreen = false
                        }
                    }
                }
            }
        }
    }
}

struct FullScreenMapView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @Binding var showMapFullScreen: Bool
    @State private var showingCreateGame = false
    @StateObject private var locationService = LocationService.shared
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(coordinateRegion: $mapViewModel.region, showsUserLocation: true, annotationItems: gameViewModel.filteredGames.isEmpty ? gameViewModel.games : gameViewModel.filteredGames) { game in
                MapAnnotation(coordinate: game.location.coordinate) {
                    GameMapPin(game: game)
                        .onTapGesture {
                            mapViewModel.selectedGame = game
                        }
                }
            }
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            showMapFullScreen = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    .padding()
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button {
                            mapViewModel.centerOnUserLocation()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        
                        Button {
                            showingCreateGame = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $mapViewModel.selectedGame) { game in
            GameDetailView(game: game)
        }
        .sheet(isPresented: $showingCreateGame) {
            CreateGameView()
                .environmentObject(gameViewModel)
        }
    }
}

struct GameMapPin: View {
    let game: Game
    
    var pinColor: Color {
        switch game.sportType {
        case .soccer: return .green
        case .basketball: return .orange
        case .volleyball: return .blue
        case .tennis: return .yellow
        case .other: return .purple
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: 40, height: 40)
                
                Text(game.sportType.icon)
                    .font(.title2)
            }
            
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption)
                .foregroundStyle(pinColor)
                .offset(y: -5)
        }
    }
}
