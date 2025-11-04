//
//  CustomButton.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI

struct CustomButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Constants.Colors.primaryColor)
                .cornerRadius(Constants.UI.cornerRadius)
        }
    }
}
