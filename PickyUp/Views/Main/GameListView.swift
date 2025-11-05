//
// GameListView.swift
//
// Views/Main/GameListView.swift
//
// Last Updated 11/4/25

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
    
    var activeFilters: [String] {
        var filters: [String] = []
        if let sport = gameViewModel.selectedSportFilter {
            filters.append(sport.rawValue)
        }
        if let sort = gameViewModel.selectedSortOption {
            filters.append(sort.rawValue)
        }
        return filters
    }
    
    var filterSummary: String {
        if activeFilters.isEmpty {
            return "All Games"
        } else if activeFilters.count <= 3 {
            return activeFilters.joined(separator: ", ")
        } else {
            let first3 = activeFilters.prefix(3).joined(separator: ", ")
            return "\(first3) +\(activeFilters.count - 3) more"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fixed Filter Header
                HStack {
                    Text(filterSummary)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(activeFilters.isEmpty ? .primary : .blue)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button {
                        showingFilters = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            if !activeFilters.isEmpty {
                                Text("\(activeFilters.count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Scrollable Games List
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
                        .refreshable {
                            // Pull to refresh - games auto-update via listener
                        }
                    }
                }
            }
            .navigationTitle("All Games")
            .navigationBarTitleDisplayMode(.large)
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
