import SwiftUI

struct UserPreviewView: View {
    let user: User
    let gamesCreated: Int
    let gamesJoined: Int

    var body: some View {
        VStack(spacing: 12) {
            // Profile image
            if let urlString = user.profilePhotoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(Text(user.initials).font(.title2).bold())
            }

            // User info
            Text(user.displayName) // ✅ fixed from `user.username`
                .font(.headline)

            // Stats
            HStack(spacing: 16) {
                VStack {
                    Text("\(gamesCreated)")
                        .font(.headline)
                    Text("Games Created")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                VStack {
                    Text("\(gamesJoined)")
                        .font(.headline)
                    Text("Games Joined")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Optional bio section
            Text("No bio yet.") // Placeholder until you add `bio` property to User later
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
