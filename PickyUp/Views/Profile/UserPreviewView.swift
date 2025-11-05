//
// UserPreviewView.swift
//
// Views/Profile/UserPreviewView.swift
//
// Last Updated 11/4/25

import SwiftUI

struct UserPreviewView: View {
    let userId: String
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(user.initials)
                        .font(.headline)
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                Text(user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
