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
        gameViewModel.filteredGames.isEmpty
        && gameViewModel.selectedSportFilter == nil
        && gameViewModel.selectedDateSort == nil
        && gameViewModel.selectedDistanceSort == nil
        && gameViewModel.selectedAttendeesSort == nil
            ? gameViewModel.games
            : gameViewModel.filteredGames
    }
    
    var activeFilters: [String] {
        var filters: [String] = []
        if let sport = gameViewModel.selectedSportFilter {
            filters.append(sport.rawValue)
        }
        if let date = gameViewModel.selectedDateSort {
            filters.append(date.rawValue)
        }
        if let distance = gameViewModel.selectedDistanceSort {
            filters.append(distance.rawValue)
        }
        if let attendees = gameViewModel.selectedAttendeesSort {
            filters.append(attendees == .most ? "Most attendees" : "Least attendees")
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
                // Sport
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
                
                // Date (single-choice)
                Section("Date") {
                    dateRow(option: .soonest, title: "Soonest")
                    dateRow(option: .latest, title: "Latest")
                    
                    if gameViewModel.selectedDateSort != nil {
                        Button {
                            gameViewModel.selectedDateSort = nil
                            gameViewModel.applyFilters()
                        } label: {
                            HStack {
                                Text("Clear Date")
                                Spacer()
                                Image(systemName: "xmark.circle")
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
                
                // Distance (single-choice)
                Section("Distance") {
                    distanceRow(option: .nearest, title: "Closest")
                    distanceRow(option: .farthest, title: "Farthest")
                    
                    if gameViewModel.selectedDistanceSort != nil {
                        Button {
                            gameViewModel.selectedDistanceSort = nil
                            gameViewModel.applyFilters()
                        } label: {
                            HStack {
                                Text("Clear Distance")
                                Spacer()
                                Image(systemName: "xmark.circle")
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
                
                // Attendees (single-choice)
                Section("Attendees") {
                    attendeesRow(option: .most, title: "Most")
                    attendeesRow(option: .least, title: "Least")
                    
                    if gameViewModel.selectedAttendeesSort != nil {
                        Button {
                            gameViewModel.selectedAttendeesSort = nil
                            gameViewModel.applyFilters()
                        } label: {
                            HStack {
                                Text("Clear Attendees")
                                Spacer()
                                Image(systemName: "xmark.circle")
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear All") {
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
    
    private func dateRow(option: DateSortOption, title: String) -> some View {
        Button {
            if gameViewModel.selectedDateSort == option {
                gameViewModel.selectedDateSort = nil
            } else {
                gameViewModel.selectedDateSort = option
            }
            gameViewModel.applyFilters()
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if gameViewModel.selectedDateSort == option {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
    }
    
    private func distanceRow(option: DistanceSortOption, title: String) -> some View {
        Button {
            if gameViewModel.selectedDistanceSort == option {
                gameViewModel.selectedDistanceSort = nil
            } else {
                gameViewModel.selectedDistanceSort = option
            }
            gameViewModel.applyFilters()
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if gameViewModel.selectedDistanceSort == option {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
    }
    
    private func attendeesRow(option: AttendeesSortOption, title: String) -> some View {
        Button {
            if gameViewModel.selectedAttendeesSort == option {
                gameViewModel.selectedAttendeesSort = nil
            } else {
                gameViewModel.selectedAttendeesSort = option
            }
            gameViewModel.applyFilters()
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if gameViewModel.selectedAttendeesSort == option {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
    }
}
