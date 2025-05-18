import Foundation
import SwiftUI

struct User: Codable, Identifiable {
    let id: UUID
    var name: String
    var profilePicturePath: String?
    var preferences: Preferences
    
    init(id: UUID = UUID(), name: String, profilePicturePath: String? = nil, preferences: Preferences = Preferences()) {
        self.id = id
        self.name = name
        self.profilePicturePath = profilePicturePath
        self.preferences = preferences
    }
    
    struct Preferences: Codable {
        var theme: Theme = .dark
        var fontSize: FontSize = .medium
        
        enum Theme: String, Codable, CaseIterable {
            case light, dark, system
        }
        
        enum FontSize: String, Codable, CaseIterable {
            case small, medium, large
        }
    }
}

class UserManager: ObservableObject {
    @Published var currentUser: User
    private let userDefaultsKey = "currentUser"
    
    init() {
        if let userData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        } else {
            // Default user
            self.currentUser = User(name: "User")
            saveUser()
        }
    }
    
    func updateProfilePicture(path: String?) {
        currentUser.profilePicturePath = path
        saveUser()
    }
    
    func updateUserName(name: String) {
        currentUser.name = name
        saveUser()
    }
    
    func updatePreferences(preferences: User.Preferences) {
        currentUser.preferences = preferences
        saveUser()
    }
    
    private func saveUser() {
        if let encoded = try? JSONEncoder().encode(currentUser) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
}