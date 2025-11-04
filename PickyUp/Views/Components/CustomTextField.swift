import SwiftUI

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .padding()
                    .background(Constants.Colors.secondaryColor.opacity(0.2))
                    .cornerRadius(Constants.UI.cornerRadius)
            } else {
                TextField(placeholder, text: $text)
                    .padding()
                    .background(Constants.Colors.secondaryColor.opacity(0.2))
                    .cornerRadius(Constants.UI.cornerRadius)
            }
        }
    }
}
