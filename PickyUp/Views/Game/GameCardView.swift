//
//  GameCardView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI

struct GameCardView: View {
    let game: Game
    @State private var attendeeCount: (going: Int, maybe: Int) = (0, 0)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(game.sportType.icon)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.displaySportName)
                        .font(.headline)
                    Text(game.creatorName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("\(attendeeCount.going)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("\(attendeeCount.maybe)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            HStack(spacing: 16) {
                Label(game.dateTime.relativeDateString, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label(game.dateTime.timeString, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Label(game.location.address, systemImage: "mappin.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .task {
            await fetchAttendeeCount()
        }
    }
    
    func fetchAttendeeCount() async {
        guard let gameId = game.id else { return }
        do {
            attendeeCount = try await GameService.shared.fetchGameAttendeeCount(gameId: gameId)
        } catch {
            print("Error fetching attendee count: \(error)")
        }
    }
}
