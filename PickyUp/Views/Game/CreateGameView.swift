//
//  CreateGameView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import Foundation
import SwiftUI
import MapKit

struct CreateGameView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var gameViewModel: GameViewModel
    
    @State private var sportType: SportType = .soccer
    @State private var customSportName = ""
    @State private var customGameTitle = "" // <-- Added
    @State private var address = ""
    @State private var selectedLocation: GameLocation?
    @State private var showingMapPicker = false
    @State private var dateTime = Date().addingTimeInterval(3600)
    @State private var duration = 60
    @State private var showCustomDuration = false
    @State private var customDuration = ""
    @State private var description = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    let durationOptions = [30, 45, 60, 90, 120]
    
    var finalDuration: Int {
        if showCustomDuration, let custom = Int(customDuration), custom > 0 {
            return custom
        }
        return duration
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Game Name (Optional)
                Section("Game Name (Optional)") {
                    TextField("e.g., Morning Run, 3v3 at the Park", text: $customGameTitle)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                
                // Game Type
                Section("Game Type") {
                    Picker("Sport", selection: $sportType) {
                        ForEach(SportType.allCases, id: \.self) { sport in
                            Text("\(sport.icon) \(sport.rawValue)")
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if sportType == .other {
                        TextField("Enter sport name", text: $customSportName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                }
                
                // When
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
                
                // Where
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
                
                // Details
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
            .navigationTitle("Create Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await createGame()
                        }
                    }
                    .disabled(isCreating || !isFormValid)
                }
            }
            .disabled(isCreating)
            .sheet(isPresented: $showingMapPicker) {
                MapPickerView(selectedLocation: $selectedLocation, address: $address)
            }
        }
    }
    
    var isFormValid: Bool {
        let hasLocation = !address.isEmpty || selectedLocation != nil
        let hasValidSport = sportType != .other || !customSportName.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty
        let hasValidDuration = !showCustomDuration || (!customDuration.isEmpty && Int(customDuration) ?? 0 > 0)
        
        return hasLocation && hasValidSport && hasValidDuration
    }
    
    func createGame() async {
        guard let user = authViewModel.currentUser else { return }
        
        isCreating = true
        errorMessage = nil
        
        do {
            let location: GameLocation
            if let selected = selectedLocation {
                location = selected
            } else {
                location = try await LocationService.shared.geocodeAddress(address)
            }
            
            let trimmedTitle = customGameTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let finalTitle = trimmedTitle.isEmpty ? nil : trimmedTitle
            
            await gameViewModel.createGame(
                sportType: sportType,
                customSportName: sportType == .other ? customSportName.trimmingCharacters(in: CharacterSet.whitespaces) : nil,
                gameTitle: finalTitle, // requires GameViewModel.createGame to accept gameTitle: String?
                location: location,
                dateTime: dateTime,
                duration: finalDuration,
                description: description.isEmpty ? nil : description,
                creatorId: user.id!,
                creatorName: user.displayName
            )
            
            if gameViewModel.errorMessage == nil {
                dismiss()
            } else {
                errorMessage = gameViewModel.errorMessage
            }
        } catch {
            errorMessage = "Could not find location. Please enter a valid address or pick on map."
        }
        
        isCreating = false
    }
}

struct MapPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: GameLocation?
    @Binding var address: String
    @StateObject private var locationService = LocationService.shared
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var isGeocodingAddress = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, showsUserLocation: true)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    Text("Tap Done to select the center location")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                        .padding()
                }
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if isGeocodingAddress { return }
                        Task {
                            isGeocodingAddress = true
                            do {
                                let location = try await LocationService.shared.reverseGeocode(coordinate: region.center)
                                selectedLocation = location
                                address = location.address
                                dismiss()
                            } catch {
                                print("Error reverse geocoding: \(error)")
                            }
                            isGeocodingAddress = false
                        }
                    }
                    .disabled(isGeocodingAddress)
                }
            }
            .onAppear {
                if let userLoc = locationService.userLocation {
                    region.center = userLoc
                }
            }
        }
    }
}
