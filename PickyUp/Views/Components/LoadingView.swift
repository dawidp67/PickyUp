//
//  LoadingView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            ProgressView("Loading...")
                .padding()
                .background(Color.white)
                .cornerRadius(10)
        }
    }
}
