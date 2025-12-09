//
//  LoginView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/30/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingForgotPassword = false
    @State private var localError: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "figure.basketball")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    
                    Text("Pickup Game\nOrganizer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocorrectionDisabled()
                        .onChange(of: email) { _, _ in
                            // Clear errors when user types
                            localError = nil
                            authViewModel.clearError()
                        }
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .onChange(of: password) { _, _ in
                            // Clear errors when user types
                            localError = nil
                            authViewModel.clearError()
                        }
                    
                    // Display local validation errors or auth errors
                    if let error = localError ?? authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                    
                    Button {
                        hideKeyboard()
                        handleLogin()
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 20)
                        } else {
                            Text("Log In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                    .disabled(authViewModel.isLoading || !isFormValid)
                    
                    Button {
                        showingForgotPassword = true
                    } label: {
                        Text("Forgot Password?")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                HStack {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign Up") {
                        showingSignUp = true
                    }
                    .fontWeight(.semibold)
                }
                .padding(.bottom, 32)
            }
            .navigationDestination(isPresented: $showingSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
            .onAppear {
                authViewModel.clearError()
                localError = nil
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespaces))
    }
    
    private func handleLogin() {
        // Clear any previous errors
        localError = nil
        authViewModel.clearError()
        
        // Trim whitespace
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        
        // Validate email format
        guard isValidEmail(trimmedEmail) else {
            localError = "Please enter a valid email address"
            return
        }
        
        // Validate password length
        guard password.count >= 6 else {
            localError = "Password must be at least 6 characters"
            return
        }
        
        // Attempt sign in
        Task {
            await authViewModel.signIn(email: trimmedEmail, password: password)
        }
    }
}


