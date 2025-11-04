//
//  GameDetailView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI

struct GameDetailView: View {
    let game: Game // FIXED: removed GameService.
    
    var body: some View {
        VStack(spacing: 20) {
            Text(game.sportType.rawValue.capitalized)
                .font(.largeTitle)
                .bold()
            
            Text(game.description ?? "")
            
            Text("Duration: \(game.duration) min")
            Text("Date: \(game.dateTime.formatted(.dateTime.month().day().hour().minute()))")
            
            Spacer()
        }
        .padding()
    }
}
