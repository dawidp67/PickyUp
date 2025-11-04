import SwiftUI

struct GameListView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @State private var showingCreateGame = false
    @State private var showingFilters = false
    
    var displayGames: [Game] {
        gameViewModel.filteredGames.isEmpty && gameViewModel.selectedSportFilter == nil && gameViewModel.selectedSortOption == nil
            ? gameViewModel.games
            : gameViewModel.filteredGames
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Header
                FilterHeaderView(showingFilters: $showingFilters)
                    .environmentObject(gameViewModel)
                
                // Games List
                Group {
                    if displayGames.isEmpty {
                        ContentUnavailableView(
                            "No Games Yet",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text("Be the first to create a game!")
                        )
                    } else {
                        List(displayGames) { game in
                            NavigationLink {
                                GameDetailView(game: game)
                            } label: {
                                GameCardView(game: game)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("All Games")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateGame = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGame) {
                CreateGameView()
                    .environmentObject(gameViewModel)
            }
            .sheet(isPresented: $showingFilters) {
                FilterView()
                    .environmentObject(gameViewModel)
                    .presentationDetents([.medium])
            }
        }
    }
}

struct FilterHeaderView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @Binding var showingFilters: Bool
    
    var activeFiltersCount: Int {
        var count = 0
        if gameViewModel.selectedSportFilter != nil { count += 1 }
        if gameViewModel.selectedSortOption != nil { count += 1 }
        return count
    }
    
    var body: some View {
        HStack {
            Text("All Games")
                .font(.headline)
            
            Spacer()
            
            Button {
                showingFilters = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    if activeFiltersCount > 0 {
                        Text("\(activeFiltersCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section("Sport") {
                    ForEach(SportType.allCases, id: \.self) { sport in
                        Button {
                            if gameViewModel.selectedSportFilter == sport {
                                gameViewModel.selectedSportFilter = nil
                            } else {
                                gameViewModel.selectedSportFilter = sport
                            }
                            gameViewModel.applyFilters()
                        } label: {
                            HStack {
                                Text("\(sport.icon) \(sport.rawValue)")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if gameViewModel.selectedSportFilter == sport {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Location") {
                    Button {
                        gameViewModel.selectedSortOption = .nearest
                        gameViewModel.applyFilters()
                    } label: {
                        HStack {
                            Text("Closest")
                                .foregroundStyle(.primary)
                            Spacer()
                            if gameViewModel.selectedSortOption == .nearest {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    Button {
                        gameViewModel.selectedSortOption = .farthest
                        gameViewModel.applyFilters()
                    } label: {
                        HStack {
                            Text("Farthest")
                                .foregroundStyle(.primary)
                            Spacer()
                            if gameViewModel.selectedSortOption == .farthest {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                
                Section("Attendees") {
                    Button {
                        gameViewModel.selectedSortOption = .leastAttendees
                        gameViewModel.applyFilters()
                    } label: {
                        HStack {
                            Text("Lowest")
                                .foregroundStyle(.primary)
                            Spacer()
                            if gameViewModel.selectedSortOption == .leastAttendees {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    Button {
                        gameViewModel.selectedSortOption = .mostAttendees
                        gameViewModel.applyFilters()
                    } label: {
                        HStack {
                            Text("Highest")
                                .foregroundStyle(.primary)
                            Spacer()
                            if gameViewModel.selectedSortOption == .mostAttendees {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        gameViewModel.clearFilters()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
