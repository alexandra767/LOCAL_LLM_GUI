import SwiftUI
import AppKit

struct ProfilePictureView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var userManager: UserManager
    @State private var showingImagePicker = false
    @State private var profileImage: NSImage?
    @State private var isImageLoaded = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Profile information
            HStack(spacing: 12) {
                // Profile picture
                Button(action: {
                    showingImagePicker = true
                }) {
                    ZStack {
                        if let image = profileImage {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        } else {
                            // Fallback to initials
                            Circle()
                                .fill(Color(NSColor.controlBackgroundColor))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(userInitials())
                                        .foregroundColor(.white)
                                        .font(.system(size: 24, weight: .semibold))
                                )
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showingImagePicker) {
                    ProfilePicturePicker(onSelected: { image in
                        saveProfileImage(image)
                        showingImagePicker = false
                    })
                    .frame(width: 300, height: 300)
                }
                
                // User information
                VStack(alignment: .leading) {
                    Text(userManager.currentUser.name)
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // Connection status
                    HStack(spacing: 6) {
                        Circle()
                            .fill(appState.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(appState.isConnected ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let model = appState.currentModel {
                            Text("• \(model)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .onAppear {
            // Load the profile image when the view appears
            profileImage = loadProfileImage()
            isImageLoaded = (profileImage != nil)
        }
    }
    
    private func userInitials() -> String {
        let name = userManager.currentUser.name
        if name.isEmpty { return "U" }
        
        let components = name.components(separatedBy: " ")
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return String(first) + String(last)
        } else if let first = name.first {
            return String(first)
        }
        return "U"
    }
    
    private func loadProfileImage() -> NSImage? {
        guard let path = userManager.currentUser.profilePicturePath else { return nil }
        
        // Check application support directory
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let seraphDir = appSupportURL.appendingPathComponent("Seraph")
        let profilePictureURL = seraphDir.appendingPathComponent(path)
        
        // Debug print to help diagnose image loading issues
        print("Loading profile image from: \(profilePictureURL.path)")
        print("File exists: \(fileManager.fileExists(atPath: profilePictureURL.path))")
        
        if fileManager.fileExists(atPath: profilePictureURL.path) {
            let image = NSImage(contentsOf: profilePictureURL)
            print("Image loaded: \(image != nil)")
            return image
        }
        
        return nil
    }
    
    private func saveProfileImage(_ image: NSImage) {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let seraphDir = appSupportURL.appendingPathComponent("Seraph")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: seraphDir.path) {
            try? fileManager.createDirectory(at: seraphDir, withIntermediateDirectories: true)
        }
        
        // Generate a unique filename
        let fileName = "profile_\(UUID().uuidString).png"
        let fileURL = seraphDir.appendingPathComponent(fileName)
        
        // Convert NSImage to PNG data and save
        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            try? pngData.write(to: fileURL)
            userManager.updateProfilePicture(path: fileName)
            
            // Update the local image state
            profileImage = image
            isImageLoaded = true
        }
    }
}

struct ProfilePicturePicker: View {
    var onSelected: (NSImage) -> Void
    @State private var selectedImage: NSImage?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Profile Picture")
                .font(.headline)
            
            if let image = selectedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .clipShape(Circle())
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(height: 150)
                    .overlay(
                        Text("No image selected")
                            .foregroundColor(.gray)
                    )
            }
            
            HStack {
                Button("Select Image") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.canChooseFiles = true
                    panel.allowedContentTypes = [.image]
                    
                    panel.beginSheetModal(for: NSApp.windows.first!) { response in
                        if response == .OK, let url = panel.url {
                            if let image = NSImage(contentsOf: url) {
                                selectedImage = image
                            }
                        }
                    }
                }
                
                if selectedImage != nil {
                    Button("Use This Picture") {
                        if let image = selectedImage {
                            onSelected(image)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ProfilePictureView()
        .environmentObject(AppState())
        .environmentObject(UserManager())
}