//
//  EditGameView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI

struct EditGameView: View {
    @State var game: Game // FIXED: removed GameService.
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Game")
                .font(.largeTitle)
                .bold()
            
            TextField("Description", text: Binding(
                get: { game.description ?? "" },
                set: { game.description = $0 }
            ))
            
            DatePicker("Date & Time", selection: $game.dateTime)
            
            Stepper("Duration: \(game.duration) min", value: $game.duration)
            
            CustomButton(title: "Update Game") {
                Task {
                    await viewModel.updateGame(gameId: game.id ?? "", updates: [
                        "description": game.description ?? "",
                        "dateTime": game.dateTime,
                        "duration": game.duration
                    ])
                }
            }
        }
        .padding()
    }
}
