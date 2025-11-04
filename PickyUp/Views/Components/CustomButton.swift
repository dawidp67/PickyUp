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
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text(title)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isDisabled ? Color.gray : Color.blue)
        .foregroundStyle(.white)
        .cornerRadius(10)
        .disabled(isDisabled || isLoading)
    }
}
