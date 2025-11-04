import SwiftUI

struct SearchView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @State private var searchText = ""
    @State private var selectedSport = "All"
    @State private var selectedCity = ""
    @State private var selectedDate = Date()
    @State private var showDateFilter = false

    let sports = ["All", "Basketball", "Soccer", "Tennis", "Volleyball", "Baseball"]

    // MARK: - Filtered games based on search input
    var filteredGames: [Game] {
        gameViewModel.games.filter { game in
            let sportName = game.displaySportName.lowercased()
            let creator = game.creatorName.lowercased()
            let location = game.location.address.lowercased()

            let matchesSport = (selectedSport == "All" || sportName.contains(selectedSport.lowercased()))
            let matchesCity = (selectedCity.isEmpty || location.contains(selectedCity.lowercased()))
            let matchesSearch = (searchText.isEmpty || creator.contains(searchText.lowercased()))

            return matchesSport && matchesCity && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // MARK: - Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search by creator...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                // MARK: - Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Picker("Sport", selection: $selectedSport) {
                            ForEach(sports, id: \.self) { sport in
                                Text(sport).tag(sport)
                            }
                        }
                        .pickerStyle(.menu)

                        TextField("City", text: $selectedCity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)

                        Button(action: { showDateFilter.toggle() }) {
                            Label("Date", systemImage: "calendar")
                        }
                    }
                    .padding(.horizontal)
                }

                if showDateFilter {
                    DatePicker("Filter by date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal)
                }

                // MARK: - Search results
                List(filteredGames, id: \.id) { game in
                    NavigationLink(destination: GameDetailView(game: game)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(game.displaySportName)
                                .font(.headline)
                            Text("\(game.sportType.icon) • \(game.location.address)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Created by \(game.creatorName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Search")
        }
    }
}
