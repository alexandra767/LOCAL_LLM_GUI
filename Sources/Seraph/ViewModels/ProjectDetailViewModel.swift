import Foundation
import SwiftUI

@MainActor
class ProjectDetailViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var showEditSheet = false
    @Published var showDeleteAlert = false
    @Published var dismissView = false
    
    let project: Project
    
    init(project: Project) {
        self.project = project
        loadChats()
    }
    
    private func loadChats() {
        chats = project.chats
    }
    
    func createChat() {
        let newChat = Chat(title: "New Chat")
        chats.append(newChat)
        saveChats()
    }
    
    func deleteChats(at offsets: IndexSet) {
        chats.remove(atOffsets: offsets)
        saveChats()
    }
    
    func deleteChat(at index: Int) {
        chats.remove(at: index)
        saveChats()
    }
    
    func deleteProject() {
        // TODO: Implement project deletion
        print("Deleting project: \(project.name)")
    }
    
    private func saveChats() {
        // TODO: Implement persistence
        print("Saving chats")
    }
    
    func updateProject(name: String, description: String) {
        // TODO: Implement project update
        print("Updating project: \(name)")
    }
}
