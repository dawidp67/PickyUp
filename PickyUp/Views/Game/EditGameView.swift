//
//  EditGameView.swift
//  PickyUp
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct EditGameView: View {
    let game: Game
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate = Date()
    @State private var duration = 60
    @State private var description = ""
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedLocation: MKMapItem?
    @State private var isSearching = false
    @State private var showingSuccess = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date & Time") {
                    DatePicker("When", selection: $selectedDate, in: Date()...)
                        .datePickerStyle(.compact)
                    
                    Picker("Duration", selection: $duration) {
                        Text("30 min").tag(30)
                        Text("1 hour").tag(60)
                        Text("1.5 hours").tag(90)
                        Text("2 hours").tag(120)
                        Text("3 hours").tag(180)
                    }
                }
                
                Section("Location") {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search for a location", text: $searchText)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .onSubmit {
                                Task {
                                    await searchLocation()
                                }
                            }
                        if isSearching {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    
                    if let selected = selectedLocation {
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
                                selectedLocation = nil
                                searchText = ""
                            }
                            .font(.caption)
                        }
                    }
                    
                    if !searchResults.isEmpty && selectedLocation == nil {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                selectedLocation = item
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
                }
                
                Section("Description (Optional)") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await updateGame()
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Game Updated!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            }
            .onAppear {
                selectedDate = game.dateTime
                duration = game.duration
                description = game.description ?? ""
                searchText = game.location.address
            }
        }
    }
    
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
    
    func updateGame() async {
        guard let gameId = game.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        var newLocation: GameLocation?
        if let selected = selectedLocation {
            newLocation = GameLocation(
                address: selected.placemark.title ?? searchText,
                latitude: selected.placemark.coordinate.latitude,
                longitude: selected.placemark.coordinate.longitude,
                placeName: selected.name
            )
        }
        
        // Build updates dictionary
        var updates: [String: Any] = [:]
        
        if let location = newLocation {
            updates["location"] = [
                "address": location.address,
                "latitude": location.latitude,
                "longitude": location.longitude,
                "placeName": location.placeName as Any
            ]
        }
        
        updates["dateTime"] = Timestamp(date: selectedDate)
        updates["duration"] = duration
        
        if description != (game.description ?? "") {
            updates["description"] = description
        }
        
        updates["updatedAt"] = Timestamp(date: Date())
        
        // Call GameService directly
        do {
            try await GameService.shared.updateGame(gameId: gameId, updates: updates)
            showingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
