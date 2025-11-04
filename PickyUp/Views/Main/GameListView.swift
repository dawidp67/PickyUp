//
//  GameListView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI

struct GameListView: View {
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.games, id: \.id) { game in
                    NavigationLink(destination: GameDetailView(game: game)) {
                        GameCardView(game: game)
                    }
                }
            }
        }
        .navigationTitle("Games")
        .task {
            // Fetch upcoming games
            viewModel.games = try! await GameService.shared.fetchUpcomingGames()
        }
    }
}

