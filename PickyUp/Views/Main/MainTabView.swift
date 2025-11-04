import SwiftUI

struct MainTabView: View {
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var gameViewModel = GameViewModel()
    
    var body: some View {
        TabView {
            GameListView()
                .tabItem {
                    Label("Games", systemImage: "sportscourt")
                }
                .environmentObject(gameViewModel)
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .environmentObject(gameViewModel)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .environmentObject(authViewModel)
        }
        .accentColor(.blue)
    }
}
