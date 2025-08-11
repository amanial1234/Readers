import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var imageManager = ProfileImageManager()
    @State private var showingEditProfile = false
    @State private var showingImagePicker = false
    @State private var editDisplayName = ""
    @State private var editBio = ""
    @State private var isUpdating = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    var body: some View {
        NavigationView {
            if !appState.isAuthenticated {
                // Not authenticated state
                VStack(spacing: 30) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("Sign in to view your profile")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Create an account to start building your reading profile")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Sign In") {
                        // This would navigate to login in a real app
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Authenticated state
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        VStack(spacing: 16) {
                            // Profile image with edit functionality
                            ZStack {
                                // Profile image
                                if let profileImage = profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else if let profileImageURL = appState.currentUser?.profileImageURL, !profileImageURL.isEmpty {
                                    AsyncImage(url: URL(string: profileImageURL)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.blue.opacity(0.2))
                                            .overlay(
                                                Image(systemName: "person")
                                                    .foregroundColor(.blue)
                                                    .font(.system(size: 40))
                                            )
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "person")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 40))
                                        )
                                }
                                
                                // Edit button overlay
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        PhotosPicker(selection: $selectedImage, matching: .images) {
                                            Image(systemName: "camera.circle.fill")
                                                .font(.title)
                                                .foregroundColor(.blue)
                                                .background(Color.white, in: Circle())
                                        }
                                    }
                                }
                                .frame(width: 100, height: 100)
                            }
                            
                            // Upload progress indicator
                            if imageManager.isUploading {
                                VStack(spacing: 8) {
                                    ProgressView(value: imageManager.uploadProgress)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .frame(width: 200)
                                    Text("Uploading... \(Int(imageManager.uploadProgress * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // User info
                            VStack(spacing: 8) {
                                Text(appState.currentUser?.displayName ?? "Unknown User")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(appState.currentUser?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let bio = appState.currentUser?.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                
                                Text("Member since \(appState.currentUser?.dateJoined ?? Date(), style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        // Stats section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reading Stats")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 16) {
                                StatCard(
                                    title: "Favorites",
                                    value: "\(appState.favoritesCount)",
                                    icon: "bookmark.fill",
                                    color: .blue
                                )
                            }
                            .onAppear {
                                // Favorites count loaded
                            }
                            .padding(.horizontal)
                        }
                        
                        // Actions
                        VStack(spacing: 12) {
                            Button(action: { showingEditProfile = true }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit Profile")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            Button(action: signOut) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    // Refresh user data and favorites count
                    await appState.refreshFavorites()
                }
                .navigationTitle("Profile")
                .sheet(isPresented: $showingEditProfile) {
                    EditProfileSheet(
                        displayName: $editDisplayName,
                        bio: $editBio,
                        isUpdating: $isUpdating,
                        currentUser: appState.currentUser,
                        onSave: updateProfile
                    )
                }
                .onAppear {
                    if let user = appState.currentUser {
                        editDisplayName = user.displayName
                        editBio = user.bio ?? ""
                        // Load local profile image if available
                        profileImage = imageManager.loadImageLocally(userId: user.id)
                    }
                }
                .onChange(of: selectedImage) { newItem in
                    Task {
                        await handleImageSelection(newItem)
                    }
                }
            }
        }
        .environmentObject(appState)
    }
    
    private func handleImageSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                
                // Update UI immediately with selected image
                await MainActor.run {
                    profileImage = image
                }
                
                // Upload and update profile
                await updateProfileImage(image)
            }
        } catch {
            print("❌ Failed to load image: \(error)")
        }
    }
    
    private func updateProfileImage(_ image: UIImage) async {
        guard let userId = appState.currentUser?.id else { return }
        
        do {
            let imageURL = try await imageManager.updateProfileImage(image, userId: userId)
            
            // For now, we don't update the user profile with the local URL
            // The image is already displayed locally, and we'll integrate Firebase Storage later
            // Profile image saved successfully
        } catch {
            print("❌ Failed to save profile image: \(error)")
        }
    }
    
    private func signOut() {
        do {
            try appState.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    private func updateProfile() {
        isUpdating = true
        
        Task {
            do {
                try await appState.updateProfile(displayName: editDisplayName, bio: editBio.isEmpty ? nil : editBio)
                showingEditProfile = false
            } catch {
                print("Error updating profile: \(error)")
            }
            
            isUpdating = false
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct EditProfileSheet: View {
    @Binding var displayName: String
    @Binding var bio: String
    @Binding var isUpdating: Bool
    let currentUser: User?
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile image preview
                VStack(spacing: 12) {
                    Text("Profile Image")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let profileImageURL = currentUser?.profileImageURL, !profileImageURL.isEmpty {
                        AsyncImage(url: URL(string: profileImageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    Image(systemName: "person")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 30))
                                )
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 30))
                            )
                    }
                    
                    Text("Tap the camera icon on your profile to change image")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Display Name", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextEditor(text: $bio)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUpdating)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
} 