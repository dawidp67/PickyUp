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
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button {
                        hideKeyboard()
                        Task {
                            await authViewModel.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
                        }
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
                    .background(email.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                    .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
                    
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
            }
        }
    }
}
