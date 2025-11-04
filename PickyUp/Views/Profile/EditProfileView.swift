//
//  EditProfileView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showingPasswordSection = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Display Name") {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                    
                    Button {
                        Task {
                            await updateDisplayName()
                        }
                    } label: {
                        if isUpdating {
                            ProgressView()
                        } else {
                            Text("Update Name")
                        }
                    }
                    .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty || isUpdating || displayName == authViewModel.currentUser?.displayName)
                }
                
                Section("Email") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    Button {
                        Task {
                            await updateEmail()
                        }
                    } label: {
                        if isUpdating {
                            ProgressView()
                        } else {
                            Text("Update Email")
                        }
                    }
                    .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || isUpdating || email == authViewModel.currentUser?.email)
                }
                
                Section {
                    Button {
                        showingPasswordSection.toggle()
                    } label: {
                        HStack {
                            Text("Change Password")
                            Spacer()
                            Image(systemName: showingPasswordSection ? "chevron.up" : "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if showingPasswordSection {
                        SecureField("New Password", text: $newPassword)
                            .textContentType(.newPassword)
                        
                        SecureField("Confirm New Password", text: $confirmNewPassword)
                            .textContentType(.newPassword)
                        
                        if !newPassword.isEmpty {
                            PasswordRequirement(text: "At least 6 characters", isMet: newPassword.count >= 6)
                                .font(.caption)
                        }
                        
                        Button {
                            Task {
                                await updatePassword()
                            }
                        } label: {
                            if isUpdating {
                                ProgressView()
                            } else {
                                Text("Update Password")
                            }
                        }
                        .disabled(newPassword.count < 6 || newPassword != confirmNewPassword || isUpdating)
                    }
                } header: {
                    Text("Password")
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                if let success = successMessage {
                    Section {
                        Text(success)
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                displayName = authViewModel.currentUser?.displayName ?? ""
                email = authViewModel.currentUser?.email ?? ""
            }
        }
    }
    
    func updateDisplayName() async {
        isUpdating = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await authViewModel.updateDisplayName(newDisplayName: displayName.trimmingCharacters(in: .whitespaces))
            successMessage = "Display name updated successfully"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isUpdating = false
    }
    
    func updateEmail() async {
        isUpdating = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await authViewModel.updateEmail(newEmail: email.trimmingCharacters(in: .whitespaces))
            successMessage = "Email updated successfully"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isUpdating = false
    }
    
    func updatePassword() async {
        guard newPassword == confirmNewPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isUpdating = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await authViewModel.updatePassword(newPassword: newPassword)
            successMessage = "Password updated successfully"
            newPassword = ""
            confirmNewPassword = ""
            showingPasswordSection = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isUpdating = false
    }
}
