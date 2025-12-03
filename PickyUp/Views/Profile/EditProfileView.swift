//
//  EditProfileView.swift
//  PickyUp
//
//  Created by Dawid W. Pankiewicz on 10/24/25.
//

import SwiftUI
import Cloudinary
import PhotosUI
import FirebaseFirestore
import UIKit
import AVFoundation

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // State for Profile Details
    @State private var displayName = ""
    @State private var email = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showingPasswordSection = false
    
    // Photo state
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data? // Final, cropped image data to display and upload
    @State private var isUploadingPhoto = false
    @State private var uploadedPhotoURL: URL?
    
    // Camera State
    @State private var showingCamera = false
    
    // Cropping flow control
    @State private var isProcessingSelection = false
    @State private var pendingImage: UIImage? // intermediate image from camera/library
    @State private var cropItem: CropItem? // drives fullScreenCover(item:)
    
    // Alerts
    @State private var showAlert = false
    @State private var alertTitle = "Notice"
    @State private var alertMessageText = ""
    
    struct CropItem: Identifiable, Equatable {
        let id = UUID()
        let image: UIImage
        static func == (lhs: CropItem, rhs: CropItem) -> Bool { lhs.id == rhs.id }
    }
    
    // Remove profile photo (Firestore field delete)
    private func removeProfilePhoto() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        isUploadingPhoto = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await UserService.shared.updateUser(userId: userId, updates: ["profilePhotoURL": FieldValue.delete()])
            await MainActor.run {
                authViewModel.currentUser?.profilePhotoURL = nil
                uploadedPhotoURL = nil
                selectedImageData = nil
                successMessage = "Profile photo removed"
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to remove photo: \(error.localizedDescription)"
            }
        }
        
        isUploadingPhoto = false
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Profile Photo Section
                Section("Profile Photo") {
                    HStack(spacing: 16) {
                        profileImageView
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Choose from library (PhotosPicker)
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                                Label("Choose Photo", systemImage: "photo.on.rectangle")
                            }
                            .onChange(of: selectedPhotoItem) { _, newItem in
                                Task { await loadSelectedPhoto(newItem) }
                            }
                            
                            // Take photo with camera
                            Button {
                                Task { await requestCameraAndPresent() }
                            } label: {
                                Label("Take Photo", systemImage: "camera")
                            }
                            
                            // Remove photo button (if photo exists)
                            if uploadedPhotoURL != nil && !isUploadingPhoto {
                                Button(role: .destructive) {
                                    Task { await removeProfilePhoto() }
                                } label: {
                                    Label("Remove Photo", systemImage: "trash")
                                }
                            }
                        }
                    }
                    
                    // Upload status/Progress
                    if isUploadingPhoto {
                        HStack {
                            ProgressView()
                            Text("Uploading...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if uploadedPhotoURL != nil && selectedImageData == nil {
                        Text("Photo uploaded successfully")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                // MARK: - Display Name Section
                Section("Display Name") {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                    
                    Button {
                        Task { await updateDisplayName() }
                    } label: {
                        if isUpdating {
                            ProgressView()
                        } else {
                            Text("Update Name")
                        }
                    }
                    .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty || isUpdating || displayName == authViewModel.currentUser?.displayName)
                }
                
                // MARK: - Email Section
                Section("Email") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    
                    Button {
                        Task { await updateEmail() }
                    } label: {
                        if isUpdating {
                            ProgressView()
                        } else {
                            Text("Update Email")
                        }
                    }
                    .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || isUpdating || email == authViewModel.currentUser?.email)
                }
                
                // MARK: - Password Section
                Section {
                    Button {
                        showingPasswordSection.toggle()
                        if !showingPasswordSection {
                            currentPassword = ""
                            newPassword = ""
                            confirmNewPassword = ""
                        }
                    } label: {
                        HStack {
                            Text("Change Password")
                            Spacer()
                            Image(systemName: showingPasswordSection ? "chevron.up" : "chevron.down")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if showingPasswordSection {
                        SecureField("Current Password", text: $currentPassword)
                            .textContentType(.password)
                        
                        SecureField("New Password", text: $newPassword)
                            .textContentType(.newPassword)
                        
                        SecureField("Confirm New Password", text: $confirmNewPassword)
                            .textContentType(.newPassword)
                        
                        if !newPassword.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                PasswordRequirement(text: "At least 6 characters", isMet: newPassword.count >= 6)
                                PasswordRequirement(text: "Passwords match", isMet: !confirmNewPassword.isEmpty && newPassword == confirmNewPassword)
                            }
                            .font(.caption)
                        }
                        
                        Button {
                            Task { await updatePassword() }
                        } label: {
                            if isUpdating {
                                ProgressView()
                            } else {
                                Text("Update Password")
                            }
                        }
                        .disabled(
                            currentPassword.isEmpty ||
                            newPassword.count < 6 ||
                            newPassword != confirmNewPassword ||
                            isUpdating
                        )
                    }
                } header: {
                    Text("Password")
                } footer: {
                    if showingPasswordSection {
                        Text("You must enter your current password to change to a new one.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // MARK: - Status Messages
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
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                displayName = authViewModel.currentUser?.displayName ?? ""
                email = authViewModel.currentUser?.email ?? ""
                if let urlString = authViewModel.currentUser?.profilePhotoURL,
                   let baseURL = URL(string: urlString) {
                    uploadedPhotoURL = cacheBustedURL(from: baseURL)
                }
            }
            .sheet(isPresented: $showingCamera, onDismiss: {
                if let img = pendingImage, cropItem == nil {
                    cropItem = CropItem(image: img)
                    pendingImage = nil
                }
            }) {
                ImagePicker(sourceType: .camera, selectedImage: $pendingImage)
            }
            .fullScreenCover(item: $cropItem) { item in
                CircularImageCropperView(
                    image: item.image,
                    outputSize: 512,
                    onCancel: { cropItem = nil },
                    onConfirm: { croppedData in
                        selectedImageData = croppedData
                        cropItem = nil
                        Task { await uploadProfilePhoto() }
                    }
                )
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessageText)
            }
        }
    }
    
    // Helper to add a cache-busting query parameter to a URL
    private func cacheBustedURL(from url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false) ?? URLComponents()
        var items = components.queryItems ?? []
        let ts = String(Int(Date().timeIntervalSince1970))
        items.removeAll { $0.name == "cb" }
        items.append(URLQueryItem(name: "cb", value: ts))
        components.queryItems = items
        return components.url ?? url
    }
    
    // MARK: - Permissions and availability
    private func requestCameraAndPresent() async {
        #if targetEnvironment(simulator)
        await MainActor.run {
            alertTitle = "Camera Unavailable"
            alertMessageText = "The iOS Simulator doesn’t have a camera. Please use a physical device, or choose a photo from your library."
            showAlert = true
        }
        return
        #else
        if showingCamera { return }
        let available = UIImagePickerController.isSourceTypeAvailable(.camera)
        guard available else {
            await MainActor.run {
                alertTitle = "Camera Unavailable"
                alertMessageText = "This device does not have a camera (or it is not available). Try Choose Photo instead."
                showAlert = true
            }
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            await MainActor.run { showingCamera = true }
        case .notDetermined:
            let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                AVCaptureDevice.requestAccess(for: .video) { allowed in
                    continuation.resume(returning: allowed)
                }
            }
            if granted {
                await MainActor.run { showingCamera = true }
            } else {
                await MainActor.run {
                    alertTitle = "Camera Access Denied"
                    alertMessageText = "Enable camera access in Settings to take a photo."
                    showAlert = true
                }
            }
        case .denied, .restricted:
            await MainActor.run {
                alertTitle = "Camera Access Denied"
                alertMessageText = "Enable camera access in Settings to take a photo."
                showAlert = true
            }
        @unknown default:
            await MainActor.run {
                alertTitle = "Camera Error"
                alertMessageText = "Unknown camera permission state."
                showAlert = true
            }
        }
        #endif
    }
    
    // MARK: - Profile Image View
    @ViewBuilder
    private var profileImageView: some View {
        if let data = selectedImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if let url = uploadedPhotoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholderInitials
                @unknown default:
                    placeholderInitials
                }
            }
        } else {
            placeholderInitials
        }
    }
    
    private var placeholderInitials: some View {
        ZStack {
            Circle().fill(Color.blue.gradient)
            Text(authViewModel.currentUser?.initials ?? "?")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Photo Handling Implementations
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item, !isProcessingSelection else { return }
        await MainActor.run { isProcessingSelection = true }
        errorMessage = nil
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    cropItem = CropItem(image: uiImage)
                    selectedPhotoItem = nil // Clear to avoid holding resources
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load image: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run { isProcessingSelection = false }
    }
    
    private func uploadProfilePhoto() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        guard let data = selectedImageData else { return }
        
        isUploadingPhoto = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Optional: recompress to JPEG ~90%
            let imageData: Data
            if let uiImage = UIImage(data: data),
               let jpeg = uiImage.jpegData(compressionQuality: 0.9) {
                imageData = jpeg
            } else {
                imageData = data
            }
            
            // Unsigned upload to Cloudinary; unique filename; folder = profile_photos
            let cleanURL = try await CloudinaryManager.shared.upload(data: imageData)
            
            // For immediate UI refresh, use a cache-busted URL locally
            let bustedURL = cacheBustedURL(from: cleanURL)
            uploadedPhotoURL = bustedURL
            
            // Save the clean URL to Firestore
            try await UserService.shared.updateUser(userId: userId, updates: ["profilePhotoURL": cleanURL.absoluteString])
            
            // Refresh current user locally (store clean URL)
            await MainActor.run {
                authViewModel.currentUser?.profilePhotoURL = cleanURL.absoluteString
                successMessage = "Profile photo updated!"
                selectedImageData = nil // Clear local selection data AFTER successful upload
            }
        } catch {
            await MainActor.run {
                let nsErr = error as NSError
                print("Cloudinary upload failed: \(nsErr.localizedDescription), userInfo: \(nsErr.userInfo)")
                errorMessage = "Upload failed: \(nsErr.localizedDescription)"
            }
        }
        
        isUploadingPhoto = false
    }
    
    // MARK: - Existing update methods
    func updateDisplayName() async {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isUpdating = true
        errorMessage = nil
        successMessage = nil
        do {
            try await authViewModel.updateDisplayName(newDisplayName: displayName)
            successMessage = "Display name updated."
        } catch {
            errorMessage = error.localizedDescription
        }
        isUpdating = false
    }
    
    func updateEmail() async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isUpdating = true
        errorMessage = nil
        successMessage = nil
        do {
            try await authViewModel.updateEmail(newEmail: email)
            successMessage = "Email updated."
        } catch {
            errorMessage = error.localizedDescription
        }
        isUpdating = false
    }
    
    func updatePassword() async {
        guard !currentPassword.isEmpty, newPassword.count >= 6, newPassword == confirmNewPassword else { return }
        isUpdating = true
        errorMessage = nil
        successMessage = nil
        do {
            try await authViewModel.reauthenticate(with: currentPassword)
            try await authViewModel.updatePassword(newPassword: newPassword)
            successMessage = "Password updated."
            currentPassword = ""
            newPassword = ""
            confirmNewPassword = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isUpdating = false
    }

    // MARK: - ImagePicker (for camera) -> returns UIImage to route through cropper
    struct ImagePicker: UIViewControllerRepresentable {
        var sourceType: UIImagePickerController.SourceType
        @Binding var selectedImage: UIImage?
        @Environment(\.dismiss) var dismiss
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: ImagePicker
            
            init(_ parent: ImagePicker) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                }
                parent.dismiss()
            }
            
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.dismiss()
            }
        }
    }
    
    // MARK: - Circular Image Cropper
    struct CircularImageCropperView: View {
        let image: UIImage
        let outputSize: CGFloat // e.g., 512
        let onCancel: () -> Void
        let onConfirm: (Data) -> Void
        
        @State private var zoomScale: CGFloat = 1.0
        @State private var lastZoomScale: CGFloat = 1.0
        @State private var offset: CGSize = .zero
        @State private var lastDragOffset: CGSize = .zero
        
        // Limits
        private let maxZoom: CGFloat = 5.0
        
        var body: some View {
            GeometryReader { geo in
                let size = geo.size
                let circleDiameter = min(size.width, size.height) - 48 // padding from edges
                let circleRadius = circleDiameter / 2
                let baseScale = circleDiameter / min(image.size.width, image.size.height)
                let currentScale = max(1.0, min(zoomScale, maxZoom)) * baseScale
                
                ZStack {
                    // Background
                    Color.black.ignoresSafeArea()
                    
                    // Image with transforms
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: image.size.width, height: image.size.height)
                        .scaleEffect(currentScale, anchor: .center)
                        .offset(offset)
                        .position(x: size.width / 2, y: size.height / 2)
                        .gesture(DragGesture()
                            .onChanged { value in
                                let proposed = CGSize(width: lastDragOffset.width + value.translation.width,
                                                      height: lastDragOffset.height + value.translation.height)
                                offset = clamp(offset: proposed, scale: currentScale, circleRadius: circleRadius)
                            }
                            .onEnded { _ in
                                lastDragOffset = offset
                            }
                        )
                        .gesture(MagnificationGesture()
                            .onChanged { value in
                                let newZoom = lastZoomScale * value
                                zoomScale = min(max(newZoom, 1.0), maxZoom)
                                offset = clamp(offset: offset, scale: currentScale, circleRadius: circleRadius)
                            }
                            .onEnded { _ in
                                lastZoomScale = zoomScale
                            }
                        )
                    
                    // Dimmed overlay with circular hole
                    overlayMask(circleDiameter: circleDiameter)
                    
                    // Top and bottom controls
                    VStack {
                        HStack {
                            Button(role: .cancel) { onCancel() } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            Text("Adjust")
                                .foregroundStyle(.white)
                                .font(.headline)
                            
                            Spacer()
                            
                            Color.clear.frame(width: 28, height: 28)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button { onCancel() } label: {
                                Text("Cancel")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                            
                            Button {
                                if let data = renderCroppedData(circleDiameter: circleDiameter, currentScale: currentScale) {
                                    onConfirm(data)
                                }
                            } label: {
                                Text("Upload")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
                .ignoresSafeArea()
            }
        }
        
        private func overlayMask(circleDiameter: CGFloat) -> some View {
            ZStack {
                Color.black.opacity(0.6)
                Circle()
                    .frame(width: circleDiameter, height: circleDiameter)
                    .blendMode(.destinationOut)
                Circle()
                    .stroke(Color.white.opacity(0.9), lineWidth: 2)
                    .frame(width: circleDiameter, height: circleDiameter)
            }
            .compositingGroup()
            .allowsHitTesting(false)
        }
        
        private func clamp(offset: CGSize, scale: CGFloat, circleRadius: CGFloat) -> CGSize {
            let halfW = (image.size.width * scale) / 2
            let halfH = (image.size.height * scale) / 2
            let maxX = max(0, halfW - circleRadius)
            let maxY = max(0, halfH - circleRadius)
            let clampedX = min(max(offset.width, -maxX), maxX)
            let clampedY = min(max(offset.height, -maxY), maxY)
            return CGSize(width: clampedX, height: clampedY)
        }
        
        private func renderCroppedData(circleDiameter: CGFloat, currentScale: CGFloat) -> Data? {
            let output = CGSize(width: outputSize, height: outputSize)
            let renderer = UIGraphicsImageRenderer(size: output)
            let data = renderer.jpegData(withCompressionQuality: 0.9) { ctx in
                let cg = ctx.cgContext
                cg.addEllipse(in: CGRect(origin: .zero, size: output))
                cg.clip()
                cg.translateBy(x: output.width / 2, y: output.height / 2)
                let viewScale = output.width / circleDiameter
                cg.scaleBy(x: viewScale, y: viewScale)
                cg.translateBy(x: offset.width, y: offset.height)
                cg.scaleBy(x: currentScale, y: currentScale)
                let imgSize = image.size
                let drawRect = CGRect(x: -imgSize.width / 2, y: -imgSize.height / 2, width: imgSize.width, height: imgSize.height)
                cg.interpolationQuality = .high
                image.draw(in: drawRect)
            }
            return data
        }
    }
    
    // MARK: - Password Requirement view
    struct PasswordRequirement: View {
        let text: String
        let isMet: Bool
        
        var body: some View {
            HStack {
                Image(systemName: isMet ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isMet ? .green : .gray)
                Text(text)
            }
        }
    }
}

// NOTE: Add these to Info.plist if missing:
// - NSCameraUsageDescription
// - NSPhotoLibraryUsageDescription
// - NSPhotoLibraryAddUsageDescription
