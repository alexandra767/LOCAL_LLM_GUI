//
//  ProjectViewModel.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing projects
class ProjectViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var allProjects: [Project] = []
    @Published var currentProject: Project?
    @Published var projectChats: [Chat] = []
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadProjects()
    }
    
    // MARK: - Public Methods
    
    /// Load all projects from storage
    func loadProjects() {
        // In a real implementation, this would load projects from CoreData
        // For now, we'll create some sample data
        let sampleProject = Project(
            name: "Sample Project",
            description: "This is a sample project for demonstration purposes.",
            documents: []
        )
        allProjects = [sampleProject]
        
        if currentProject == nil && !allProjects.isEmpty {
            setCurrentProject(allProjects[0].id)
        }
    }
    
    /// Create a new project
    func createProject(name: String, description: String, color: String) -> UUID {
        let newProject = Project(
            name: name,
            description: description,
            documents: [],
            color: color
        )
        
        allProjects.insert(newProject, at: 0)
        setCurrentProject(newProject.id)
        return newProject.id
    }
    
    /// Set the current active project
    func setCurrentProject(_ projectId: UUID) {
        currentProject = allProjects.first { $0.id == projectId }
        loadProjectChats()
    }
    
    /// Load all chats for the current project
    func loadProjectChats() {
        guard let project = currentProject else {
            projectChats = []
            return
        }
        
        // In a real implementation, this would fetch chats from CoreData
        // For now, we'll use the placeholder method on Project
        projectChats = project.getChats()
    }
    
    /// Update a project
    func updateProject(_ project: Project) {
        if let index = allProjects.firstIndex(where: { $0.id == project.id }) {
            allProjects[index] = project
            
            // If this is the current project, update it too
            if currentProject?.id == project.id {
                currentProject = project
            }
        }
    }
    
    /// Delete a project
    func deleteProject(_ projectId: UUID) {
        allProjects.removeAll { $0.id == projectId }
        
        // If we deleted the current project, select a new one
        if currentProject?.id == projectId {
            currentProject = allProjects.first
            loadProjectChats()
        }
    }
    
    /// Pin or unpin a project
    func togglePinProject(_ projectId: UUID) {
        guard var project = allProjects.first(where: { $0.id == projectId }) else { return }
        
        project.isPinned.toggle()
        updateProject(project)
    }
    
    /// Add a document to a project
    func addDocument(to projectId: UUID, document: DocumentAttachment) {
        guard var project = allProjects.first(where: { $0.id == projectId }) else { return }
        
        project.documents.append(document)
        project.updatedAt = Date()
        updateProject(project)
    }
    
    /// Remove a document from a project
    func removeDocument(from projectId: UUID, documentId: UUID) {
        guard var project = allProjects.first(where: { $0.id == projectId }) else { return }
        
        project.documents.removeAll { $0.id == documentId }
        project.updatedAt = Date()
        updateProject(project)
    }
    
    /// Create a new chat in the current project
    func createChatInProject(model: LLMModel, systemPrompt: String) -> UUID {
        guard let project = currentProject else {
            fatalError("Cannot create chat without a current project")
        }
        
        // This would integrate with ChatViewModel in a real implementation
        // For now, just creating a placeholder chat
        let chat = Chat(
            title: "New Project Chat",
            messages: [],
            projectId: project.id,
            model: model.id,
            systemPrompt: systemPrompt
        )
        
        projectChats.insert(chat, at: 0)
        return chat.id
    }
    
    /// Export project data
    func exportProject(_ projectId: UUID, format: ExportFormat) -> URL? {
        guard allProjects.contains(where: { $0.id == projectId }) else { return nil }
        
        // In a real implementation, this would actually export the project
        // For now, returning nil as a placeholder
        return nil
    }
    
    /// Get pinned projects
    var pinnedProjects: [Project] {
        allProjects.filter { $0.isPinned }
    }
    
    /// Get recent projects
    var recentProjects: [Project] {
        allProjects.sorted { $0.updatedAt > $1.updatedAt }.prefix(5).map { $0 }
    }
}