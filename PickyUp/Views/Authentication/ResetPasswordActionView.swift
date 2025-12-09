//
//  ResetPassword.swift
//  PickyUp
//
//  Created by Dawid on 12/9/25.
//
import SwiftUI
import FirebaseAuth

struct ResetPasswordActionView: View {
    let actionURL: URL
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var isVerifying = true
    @State private var verificationError: String?
    @State private var emailForCode: String?
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var submitError: String?
    @State private var submitSuccess = false
    
    private var oobCode: String? {
        URLComponents(url: actionURL, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "oobCode" })?
            .value
    }
    
    private var mode: String? {
        URLComponents(url: actionURL, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "mode" })?
            .value
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isVerifying {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Verifying reset link…")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else if let error = verificationError {
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.octagon.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.red)
                        Text("Invalid or expired link")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Close") { dismiss() }
                            .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    formView
                }
            }
            .navigationTitle("Set New Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { verifyLink() }
            .alert("Password Updated", isPresented: $submitSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your password has been reset. You can now log in with the new password.")
            }
        }
    }
    
    @ViewBuilder
    private var formView: some View {
        VStack(spacing: 16) {
            if let email = emailForCode {
                Text("Reset password for \(email)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            SecureField("New Password", text: $newPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            SecureField("Confirm New Password", text: $confirmPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            if !newPassword.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    PasswordRequirementRow(text: "At least 6 characters", isMet: newPassword.count >= 6)
                    PasswordRequirementRow(text: "Passwords match", isMet: !confirmPassword.isEmpty && newPassword == confirmPassword)
                }
                .font(.caption)
                .padding(.horizontal, 4)
            }
            
            if let error = submitError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Task { await confirmReset() }
            } label: {
                if isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Text("Update Password").fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSubmitEnabled ? Color.blue : Color.gray)
            .foregroundStyle(.white)
            .cornerRadius(10)
            .disabled(!isSubmitEnabled || isSubmitting)
            
            Spacer(minLength: 0)
        }
        .padding()
    }
    
    private var isSubmitEnabled: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }
    
    private func verifyLink() {
        guard mode == "resetPassword", let code = oobCode else {
            verificationError = "Unsupported or missing action parameters."
            isVerifying = false
            return
        }
        
        isVerifying = true
        verificationError = nil
        
        Task {
            do {
                let email = try await Auth.auth().verifyPasswordResetCode(code)
                await MainActor.run {
                    emailForCode = email
                    isVerifying = false
                }
            } catch {
                await MainActor.run {
                    verificationError = friendlyError(error)
                    isVerifying = false
                }
            }
        }
    }
    
    private func confirmReset() async {
        guard let code = oobCode else { return }
        submitError = nil
        isSubmitting = true
        
        do {
            try await Auth.auth().confirmPasswordReset(withCode: code, newPassword: newPassword)
            await MainActor.run {
                submitSuccess = true
                isSubmitting = false
            }
        } catch {
            await MainActor.run {
                submitError = friendlyError(error)
                isSubmitting = false
            }
        }
    }
    
    private func friendlyError(_ error: Error) -> String {
        let ns = error as NSError
        if let code = AuthErrorCode(_bridgedNSError: ns) {
            switch code.code {
            case .expiredActionCode: return "This reset link has expired. Please request a new one."
            case .invalidActionCode: return "This reset link is invalid. Please request a new one."
            case .weakPassword: return "Password is too weak. Use at least 6 characters."
            default: break
            }
        }
        return error.localizedDescription
    }
}

private struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isMet ? .green : .gray)
            Text(text)
        }
    }
}
