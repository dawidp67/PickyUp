//
//  MapAnnotationView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI
import MapKit

struct MapAnnotationView: View {
    let game: Game

    var body: some View {
        VStack(spacing: 4) {
            Text(game.sportType.rawValue)
                .font(.caption)
                .bold()
                .padding(5)
                .background(Constants.Colors.primaryColor)
                .foregroundColor(.white)
                .cornerRadius(5)
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.red)
                .font(.title)
        }
    }
}
