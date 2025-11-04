import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

extension Color {
    static let primaryColor = Color("PrimaryColor") // Add in Assets
    static let secondaryColor = Color("SecondaryColor")
}
