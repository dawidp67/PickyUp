//
//  CreateGameView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI

struct CreateGameView: View {
    @State private var sportType: SportType = .soccer
    @State private var location = GameLocation(address: "", latitude: 0, longitude: 0) // FIXED: address first
    @State private var dateTime = Date()
    @State private var duration = 60
    @State private var description = ""
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Game")
                .font(.largeTitle)
                .bold()
            
            Picker("Sport", selection: $sportType) {
                ForEach(SportType.allCases, id: \.self) { sport in
                    Text(sport.rawValue.capitalized)
                }
            }
            
            TextField("Description", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            DatePicker("Date & Time", selection: $dateTime)
            
            Stepper("Duration: \(duration) minutes", value: $duration, in: 15...240, step: 15)
            
            CustomButton(title: "Create Game") {
                Task {
                    await viewModel.createGame(
                        sportType: sportType,
                        location: location,
                        dateTime: dateTime,
                        duration: duration,
                        description: description,
                        creatorId: "currentUserId",
                        creatorName: "Current User"
                    )
                }
            }
        }
        .padding()
    }
}
