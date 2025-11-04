//
//  EditProfileView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EditProfileView: View {
    @State private var fullName = ""
    @State private var errorMessage = ""
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Profile")
                .font(.largeTitle)
                .bold()
            
            CustomTextField(placeholder: "Full Name", text: $fullName)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            CustomButton(title: "Save") {
                updateProfile()
            }
        }
        .padding()
        .task {
            loadProfile()
        }
    }
    
    private func loadProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection(Constants.Firestore.usersCollection).document(uid)
        docRef.getDocument { snapshot, error in
            if let data = snapshot?.data() {
                fullName = data["fullName"] as? String ?? ""
            }
        }
    }
    
    private func updateProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection(Constants.Firestore.usersCollection).document(uid).updateData([
            "fullName": fullName
        ]) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
}
