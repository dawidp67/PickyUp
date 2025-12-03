//AuthViewModel

import Foundation
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let user = user {
                    self.isAuthenticated = true
                    await self.fetchCurrentUser(userId: user.uid)
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
                self.isLoading = false
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signUp(email: email, password: password, displayName: displayName)
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try authService.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.resetPassword(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateEmail(newEmail: String) async throws {
        try await authService.updateEmail(newEmail: newEmail)
        if let userId = currentUser?.id {
            await fetchCurrentUser(userId: userId)
        }
    }
    
    func updatePassword(newPassword: String) async throws {
        try await authService.updatePassword(newPassword: newPassword)
    }
    
    // MARK: - Reauthenticate User
    func reauthenticate(with password: String) async throws {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            throw NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
    }
    
    func updateDisplayName(newDisplayName: String) async throws {
        guard let userId = currentUser?.id else { return }
        try await authService.updateDisplayName(userId: userId, newDisplayName: newDisplayName)
        await fetchCurrentUser(userId: userId)
    }
    
    private func fetchCurrentUser(userId: String) async {
        do {
            currentUser = try await authService.fetchUser(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
