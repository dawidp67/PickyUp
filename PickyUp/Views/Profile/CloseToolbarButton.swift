import SwiftUI

struct CloseToolbarButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.gray)
        }
        .accessibilityLabel("Close")
    }
}
