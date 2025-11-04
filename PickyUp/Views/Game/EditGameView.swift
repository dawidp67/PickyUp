//
//  EditGameView.swift
//  PickyUp
//
//  Last Edited 11/3/25
//

import SwiftUI
import MapKit

struct EditGameView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameViewModel: GameViewModel
    
    @State var game: Game
    @State private var selectedDate: Date
    @State private var duration: Int
    @State private var description: String
    @State private var address: String
    @State private var selectedLocation: GameLocation?
    @State private var showCustomDuration = false
    @State private var customDuration = ""
    
    // Map search
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var isSearching = false
    @State private var showingMapPicker = false
    
    // Feedback
    @State private var showingSuccess = false
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    let durationOptions = [30, 45, 60, 90, 120]
    
    init(game: Game) {
        self._game = State(initialValue: game)
        self._selectedDate = State(initialValue: game.dateTime)
        self._duration = State(initialValue: game.duration)
        self._description = State(initialValue: game.description ?? "")
        self._address = State(initialValue: game.location.address)
        self._selectedLocation = State(initialValue: game.location)
    }
    
    var finalDuration: Int {
        if showCustomDuration, let custom = Int(customDuration), custom > 0 {
            return custom
        }
        return duration
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Date & Time
                Section("When") {
                    DatePicker("Date & Time", selection: $selectedDate, in: Date()...)
                    
                    Picker("Duration", selection: $duration) {
                        ForEach(durationOptions, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                        Text("Other").tag(-1)
                    }
                    .onChange(of: duration) { _, newValue in
                        showCustomDuration = (newValue == -1)
                        if !showCustomDuration {
                            customDuration = ""
                        }
                    }
                    
                    if showCustomDuration {
                        TextField("Custom duration (minutes)", text: $customDuration)
                            .keyboardType(.numberPad)
                    }
                }
                
                // MARK: - Location Section
                Section("Location") {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search for a location", text: $searchText)
                            .autocorrectionDisabled()
                            .onSubmit { Task { await searchLocation() } }
                        if isSearching { ProgressView().controlSize(.small) }
                    }
                    
                    Button {
                        showingMapPicker = true
                    } label: {
                        Label("Pick on Map", systemImage: "map")
                    }
                    
                    if let selected = selectedMapItem {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                            VStack(alignment: .leading) {
                                Text(selected.name ?? "Selected Location")
                                    .font(.subheadline)
                                if let address = selected.placemark.title {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button("Change") {
                                selectedMapItem = nil
                                searchText = ""
                            }
                            .font(.caption)
                        }
                    } else if !searchResults.isEmpty {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                selectedMapItem = item
                                address = item.placemark.title ?? address
                                searchText = item.name ?? ""
                                searchResults = []
                            } label: {
                                HStack {
                                    Image(systemName: "mappin")
                                    VStack(alignment: .leading) {
                                        Text(item.name ?? "Unknown")
                                            .foregroundStyle(.primary)
                                        if let address = item.placemark.title {
                                            Text(address)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if let location = selectedLocation {
                        Text("Current: \(location.address)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // MARK: - Description
                Section("Details (Optional)") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                // MARK: - Error
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await updateGame() } }
                        .disabled(isUpdating || gameViewModel.isLoading)
                }
            }
            .sheet(isPresented: $showingMapPicker) {
                MapPickerView(selectedLocation: $selectedLocation, address: $address)
            }
            .alert("Game Updated!", isPresented: $showingSuccess) {
                Button("OK") { dismiss() }
            }
            .onAppear {
                if !durationOptions.contains(duration) {
                    showCustomDuration = true
                    customDuration = "\(duration)"
                    duration = -1
                }
                searchText = game.location.address
            }
        }
    }
    
    // MARK: - Search Function
    func searchLocation() async {
        isSearching = true
        searchResults = []
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            searchResults = response.mapItems
        } catch {
            print("Search error: \(error)")
        }
        isSearching = false
    }
    
    // MARK: - Update Function
    func updateGame() async {
        guard let gameId = game.id else { return }
        isUpdating = true
        errorMessage = nil
        
        do {
            var newLocation = game.location
            
            if let mapItem = selectedMapItem {
                newLocation = GameLocation(
                    address: mapItem.placemark.title ?? address,
                    latitude: mapItem.placemark.coordinate.latitude,
                    longitude: mapItem.placemark.coordinate.longitude,
                    placeName: mapItem.name
                )
            } else if let selected = selectedLocation {
                newLocation = selected
            }
            
            await gameViewModel.updateGame(
                gameId: gameId,
                location: newLocation,
                dateTime: selectedDate,
                duration: finalDuration
            )
            
            if description != (game.description ?? "") {
                try await GameService.shared.updateGame(gameId: gameId, updates: ["description": description])
            }
            
            if gameViewModel.errorMessage == nil {
                showingSuccess = true
            } else {
                errorMessage = gameViewModel.errorMessage
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isUpdating = false
    }
}
