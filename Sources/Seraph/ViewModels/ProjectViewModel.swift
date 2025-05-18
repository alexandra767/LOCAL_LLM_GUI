import Foundation
import SwiftUI

@MainActor
class ProjectViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var showNewProjectSheet = false
    @Published var selectedProject: Project?
    @Published var showProjectDetail = false
    @Published var contextText = ""
    @Published var modelResponse = ""
    @Published var isLoading = false
    @Published var showFileImporter = false
    @Published var showFolderImporter = false
    @Published var showingAllProjects = false // Controls if we're showing expanded view
    
    init() {
        loadProjects()
    }
    
    private func loadProjects() {
        // Load from persistence
        // Starting with empty projects list so user can create their own
        projects = []
        
        // In a real app, you would load saved projects from disk here
    }
    
    func createProject(name: String, description: String) {
        let newProject = Project(name: name, description: description)
        projects.append(newProject)
        saveProjects()
    }
    
    func deleteProjects(at offsets: IndexSet) {
        projects.remove(atOffsets: offsets)
        saveProjects()
    }
    
    func deleteProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects.remove(at: index)
            saveProjects()
        }
    }
    
    func updateProject(_ project: Project, name: String, description: String) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            var updatedProject = project
            updatedProject.name = name
            updatedProject.description = description
            projects[index] = updatedProject
            saveProjects()
        }
    }
    
    func toggleStar(for project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            var updatedProject = project
            updatedProject.isStarred.toggle()
            projects[index] = updatedProject
            saveProjects()
        }
    }
    
    private func saveProjects() {
        // TODO: Implement persistence
    }
    
    func addFilesToContext(_ urls: [URL]) {
        for url in urls {
            do {
                let fileContent = try String(contentsOf: url)
                contextText += "\n\n# File: \(url.lastPathComponent)\n\n"
                contextText += fileContent
            } catch {
                print("Error reading file \(url.lastPathComponent): \(error)")
            }
        }
    }
    
    func addFolderToContext(_ url: URL) {
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            
            // Add folder name to context
            contextText += "\n\n# Folder: \(url.lastPathComponent)\n\n"
            
            // Get text files only
            let textFiles = contents.filter { 
                let fileExtension = $0.pathExtension.lowercased()
                return ["txt", "md", "swift", "java", "py", "js", "html", "css", "json", "xml"].contains(fileExtension) 
            }
            
            // Add content of each text file
            for fileURL in textFiles {
                do {
                    let fileContent = try String(contentsOf: fileURL)
                    contextText += "## File: \(fileURL.lastPathComponent)\n\n"
                    contextText += fileContent + "\n\n"
                } catch {
                    print("Error reading file \(fileURL.lastPathComponent): \(error)")
                }
            }
        } catch {
            print("Error reading folder \(url.lastPathComponent): \(error)")
        }
    }
    
    func submitToModel() {
        isLoading = true
        
        // In a real app, this would call the LLM service to process the query
        // For now, we'll simulate a response after a delay
        
        let prompt = contextText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Simulate async LLM call
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Generate sample response based on input
            var response = ""
            
            if prompt.lowercased().contains("hello") || prompt.lowercased().contains("hi") {
                response = "Hello! How can I help you with your project today?"
            } else if prompt.lowercased().contains("project") {
                response = "I see you're working on a project. Would you like me to help you organize your thoughts or provide specific assistance with implementation?"
            } else if prompt.lowercased().contains("context") || prompt.lowercased().contains("file") {
                response = "I've analyzed the context you've provided. Let me know if you want more specific information about any part of it."
            } else {
                response = "I understand your request. In a completed implementation, I would process your input using the selected LLM and provide a relevant response. How else can I assist you with your projects?"
            }
            
            // Update the response
            modelResponse = response
            isLoading = false
            
            // Clear the input after sending
            contextText = ""
        }
    }
}
