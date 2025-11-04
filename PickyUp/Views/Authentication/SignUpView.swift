//
//  SignUpView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/30/25.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var localError: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("Create Account")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                // Sign up form
                VStack(spacing: 16) {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    // Password requirements
                    if !password.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            PasswordRequirement(
                                text: "At least 6 characters",
                                isMet: password.count >= 6
                            )
                        }
                        .font(.caption)
                        .padding(.horizontal, 4)
                    }
                    
                    // Error message
                    if let error = localError ?? authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Sign up button
                    Button {
                        validateAndSignUp()
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                    .disabled(!isFormValid || authViewModel.isLoading)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password.count >= 6
    }
    
    func validateAndSignUp() {
        // Clear previous errors
        localError = nil
        authViewModel.clearError()
        
        // Validate passwords match
        guard password == confirmPassword else {
            localError = "Passwords do not match"
            return
        }
        
        // Validate password length
        guard password.count >= 6 else {
            localError = "Password must be at least 6 characters"
            return
        }
        
        // Attempt sign up
        Task {
            await authViewModel.signUp(email: email, password: password, displayName: displayName)
            
            // If successful, dismiss
            if authViewModel.isAuthenticated {
                dismiss()
            }
        }
    }
}

struct PasswordRequirement: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isMet ? .green : .secondary)
            Text(text)
                .foregroundStyle(isMet ? .primary : .secondary)
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
