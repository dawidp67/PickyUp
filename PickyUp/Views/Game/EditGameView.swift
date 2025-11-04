//
//  EditGameView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI
import MapKit

struct EditGameView: View {
    @Environment(\.dismiss) var dismiss
    @State var game: Game
    @StateObject private var viewModel = GameViewModel()
    
    @State private var address: String
    @State private var selectedLocation: GameLocation?
    @State private var showingMapPicker = false
    @State private var dateTime: Date
    @State private var duration: Int
    @State private var showCustomDuration = false
    @State private var customDuration = ""
    @State private var description: String
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    let durationOptions = [30, 45, 60, 90, 120]
    
    init(game: Game) {
        self._game = State(initialValue: game)
        self._address = State(initialValue: game.location.address)
        self._dateTime = State(initialValue: game.dateTime)
        self._duration = State(initialValue: game.duration)
        self._description = State(initialValue: game.description ?? "")
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
                Section("When") {
                    DatePicker("Date & Time", selection: $dateTime, in: Date()...)
                    
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
                
                Section("Where") {
                    TextField("Address or Location", text: $address)
                        .textInputAutocapitalization(.words)
                    
                    Button {
                        showingMapPicker = true
                    } label: {
                        Label("Pick on Map", systemImage: "map")
                    }
                    
                    if let location = selectedLocation {
                        Text("Selected: \(location.address)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Details (Optional)") {
                    TextField("Add any details...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
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
                    .disabled(isUpdating)
                }
            }
            .disabled(isUpdating)
            .sheet(isPresented: $showingMapPicker) {
                MapPickerView(selectedLocation: $selectedLocation, address: $address)
            }
            .onAppear {
                if !durationOptions.contains(duration) {
                    showCustomDuration = true
                    customDuration = "\(duration)"
                    duration = -1
                }
            }
        }
    }
    
    func updateGame() async {
        guard let gameId = game.id else { return }
        
        isUpdating = true
        errorMessage = nil
        
        do {
            let location: GameLocation
            if let selected = selectedLocation, selected.address != game.location.address {
                location = selected
            } else if address != game.location.address {
                location = try await LocationService.shared.geocodeAddress(address)
            } else {
                location = game.location
            }
            
            await viewModel.updateGame(
                gameId: gameId,
                location: location,
                dateTime: dateTime,
                duration: finalDuration
            )
            
            if let desc = description.isEmpty ? nil : description {
                try await GameService.shared.updateGame(gameId: gameId, updates: ["description": desc])
            }
            
            if viewModel.errorMessage == nil {
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isUpdating = false
    }
}
