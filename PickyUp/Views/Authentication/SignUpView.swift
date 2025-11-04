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
                
                VStack(spacing: 16) {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocorrectionDisabled()
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocorrectionDisabled()
                    
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
                    
                    if let error = localError ?? authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button {
                        hideKeyboard()
                        validateAndSignUp()
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 20)
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
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
        .onAppear {
            authViewModel.clearError()
            localError = nil
        }
    }
    
    var isFormValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 6 &&
        !confirmPassword.isEmpty
    }
    
    func validateAndSignUp() {
        localError = nil
        authViewModel.clearError()
        
        guard password == confirmPassword else {
            localError = "Passwords do not match"
            return
        }
        
        guard password.count >= 6 else {
            localError = "Password must be at least 6 characters"
            return
        }
        
        Task {
            await authViewModel.signUp(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                displayName: displayName.trimmingCharacters(in: .whitespaces)
            )
            
            await MainActor.run {
                if authViewModel.isAuthenticated && authViewModel.errorMessage == nil {
                    dismiss()
                }
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
