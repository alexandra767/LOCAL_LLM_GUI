import Foundation
import SwiftUI

@MainActor
class SystemPromptViewModel: ObservableObject {
    @Published var prompts: [SystemPrompt] = []
    @Published var showNewPromptSheet = false
    @Published var selectedPrompt: SystemPrompt?
    
    private let defaults = UserDefaults.standard
    private let key = "SystemPrompts"
    
    init() {
        loadPrompts()
    }
    
    private func loadPrompts() {
        if let data = defaults.data(forKey: key),
           let savedPrompts = try? JSONDecoder().decode([SystemPrompt].self, from: data) {
            prompts = savedPrompts
        } else {
            // Add default prompts
            prompts = [
                SystemPrompt(
                    name: "Code Assistant",
                    description: "Helps with code writing and debugging",
                    content: "You are a helpful code assistant. You understand multiple programming languages and can help with writing, debugging, and explaining code."
                ),
                SystemPrompt(
                    name: "Technical Writer",
                    description: "Creates technical documentation",
                    content: "You are a technical writer. You create clear, concise, and accurate documentation for technical products and services."
                ),
                SystemPrompt(
                    name: "Creative Writer",
                    description: "Assists with creative writing",
                    content: "You are a creative writing assistant. You help with story development, character creation, and plot structuring."
                )
            ]
        }
    }
    
    func createPrompt(name: String, description: String, content: String) {
        let newPrompt = SystemPrompt(name: name, description: description, content: content)
        prompts.append(newPrompt)
        savePrompts()
    }
    
    func updatePrompt(_ prompt: SystemPrompt, name: String, description: String, content: String) {
        if let index = prompts.firstIndex(where: { $0.id == prompt.id }) {
            var updatedPrompt = prompt
            updatedPrompt.name = name
            updatedPrompt.description = description
            updatedPrompt.content = content
            prompts[index] = updatedPrompt
            savePrompts()
        }
    }
    
    func deletePrompt(at indexSet: IndexSet) {
        prompts.remove(atOffsets: indexSet)
        savePrompts()
    }
    
    func deletePrompts(at offsets: IndexSet) {
        prompts.remove(atOffsets: offsets)
        savePrompts()
    }
    
    func toggleFavorite(for prompt: SystemPrompt) {
        if let index = prompts.firstIndex(where: { $0.id == prompt.id }) {
            var updatedPrompt = prompt
            updatedPrompt.isFavorite.toggle()
            prompts[index] = updatedPrompt
            savePrompts()
        }
    }
    
    private func savePrompts() {
        if let data = try? JSONEncoder().encode(prompts) {
            defaults.set(data, forKey: key)
        }
    }
    
    func applyPrompt(_ prompt: SystemPrompt) {
        // TODO: Apply prompt to current chat
        print("Applying prompt: \(prompt.name)")
    }
}
