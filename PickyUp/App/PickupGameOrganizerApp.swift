import SwiftUI
import FirebaseCore

@main
struct PickupGameOrganizerApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var gameViewModel = GameViewModel()
    
    init() {
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(gameViewModel)
        }
    }
}
