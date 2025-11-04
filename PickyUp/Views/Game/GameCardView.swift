//
//  GameCardView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI

struct GameCardView: View {
    let game: Game // FIXED: removed GameService.
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(game.sportType.rawValue.capitalized)
                .font(.headline)
            Text(game.description ?? "")
                .font(.subheadline)
            Text("Date: \(game.dateTime.formatted(.dateTime.month().day().hour().minute()))")
                .font(.caption)
        }
        .padding()
        .background(Constants.Colors.secondaryColor.opacity(0.2)) // Now works with extension
        .cornerRadius(Constants.UI.cornerRadius) // Now finds Constants
    }
}
