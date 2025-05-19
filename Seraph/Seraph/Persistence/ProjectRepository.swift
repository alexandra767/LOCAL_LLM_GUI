//
//  ProjectRepository.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import CoreData
import Combine

/// Repository for managing projects and related documents
class ProjectRepository {
    private let persistenceController: PersistenceController
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Project Operations
    
    /// Get all projects
    func getAllProjects() -> [Project] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDProject> = CDProject.fetchRequest()
        
        // Sort by updated date, most recent first
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let cdProjects = try context.fetch(fetchRequest)
            return cdProjects.map { $0.toModel() }
        } catch {
            print("Error fetching projects: \(error)")
            return []
        }
    }
    
    /// Get pinned projects
    func getPinnedProjects() -> [Project] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDProject> = CDProject.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "isPinned == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let cdProjects = try context.fetch(fetchRequest)
            return cdProjects.map { $0.toModel() }
        } catch {
            print("Error fetching pinned projects: \(error)")
            return []
        }
    }
    
    /// Get recent projects
    func getRecentProjects(limit: Int = 5) -> [Project] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDProject> = CDProject.fetchRequest()
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        fetchRequest.fetchLimit = limit
        
        do {
            let cdProjects = try context.fetch(fetchRequest)
            return cdProjects.map { $0.toModel() }
        } catch {
            print("Error fetching recent projects: \(error)")
            return []
        }
    }
    
    /// Get project by ID
    func getProject(id: UUID) -> Project? {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDProject> = CDProject.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let cdProjects = try context.fetch(fetchRequest)
            return cdProjects.first?.toModel()
        } catch {
            print("Error fetching project with ID \(id): \(error)")
            return nil
        }
    }
    
    /// Save a project
    func saveProject(_ project: Project) -> Project {
        let context = persistenceController.container.viewContext
        
        // Check if project already exists
        if let existingProject = findCDProject(id: project.id, context: context) {
            existingProject.update(from: project, context: context)
            saveContext(context)
            return existingProject.toModel()
        } else {
            // Create new project
            let newProject = CDProject.create(from: project, context: context)
            
            // Create documents
            for document in project.documents {
                let cdDocument = CDDocumentAttachment.create(from: document, context: context)
                newProject.addToDocuments(cdDocument)
            }
            
            saveContext(context)
            return newProject.toModel()
        }
    }
    
    /// Delete a project
    func deleteProject(id: UUID) {
        let context = persistenceController.container.viewContext
        
        if let projectToDelete = findCDProject(id: id, context: context) {
            context.delete(projectToDelete)
            saveContext(context)
        }
    }
    
    /// Toggle whether a project is pinned
    func togglePinProject(id: UUID) -> Project? {
        let context = persistenceController.container.viewContext
        
        guard let project = findCDProject(id: id, context: context) else {
            print("Project with ID \(id) not found")
            return nil
        }
        
        project.isPinned = !project.isPinned
        project.updatedAt = Date()
        
        saveContext(context)
        return project.toModel()
    }
    
    /// Add a document to a project
    func addDocument(_ document: DocumentAttachment, toProjectWithId projectId: UUID) -> DocumentAttachment? {
        let context = persistenceController.container.viewContext
        
        guard let project = findCDProject(id: projectId, context: context) else {
            print("Project with ID \(projectId) not found")
            return nil
        }
        
        let cdDocument = CDDocumentAttachment.create(from: document, context: context)
        project.addToDocuments(cdDocument)
        
        // Update project's updatedAt timestamp
        project.updatedAt = Date()
        
        saveContext(context)
        return cdDocument.toModel()
    }
    
    /// Remove a document from a project
    func removeDocument(documentId: UUID, fromProjectWithId projectId: UUID) {
        let context = persistenceController.container.viewContext
        
        guard let project = findCDProject(id: projectId, context: context) else {
            print("Project with ID \(projectId) not found")
            return
        }
        
        if let document = findCDDocument(id: documentId, context: context) {
            project.removeFromDocuments(document)
            
            // Update project's updatedAt timestamp
            project.updatedAt = Date()
            
            saveContext(context)
        }
    }
    
    /// Get documents for a project
    func getDocumentsForProject(projectId: UUID) -> [DocumentAttachment] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDDocumentAttachment> = CDDocumentAttachment.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "project.id == %@", projectId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let cdDocuments = try context.fetch(fetchRequest)
            return cdDocuments.map { $0.toModel() }
        } catch {
            print("Error fetching documents for project \(projectId): \(error)")
            return []
        }
    }
    
    /// Search for projects matching a query
    func searchProjects(query: String) -> [Project] {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<CDProject> = CDProject.fetchRequest()
        
        // Search in name or description
        let namePredicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
        let descriptionPredicate = NSPredicate(format: "projectDescription CONTAINS[cd] %@", query)
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [namePredicate, descriptionPredicate])
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        
        do {
            let cdProjects = try context.fetch(fetchRequest)
            return cdProjects.map { $0.toModel() }
        } catch {
            print("Error searching projects: \(error)")
            return []
        }
    }
    
    // MARK: - Private Helpers
    
    /// Find a CDProject entity by ID
    private func findCDProject(id: UUID, context: NSManagedObjectContext) -> CDProject? {
        let fetchRequest: NSFetchRequest<CDProject> = CDProject.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error finding project: \(error)")
            return nil
        }
    }
    
    /// Find a CDDocumentAttachment entity by ID
    private func findCDDocument(id: UUID, context: NSManagedObjectContext) -> CDDocumentAttachment? {
        let fetchRequest: NSFetchRequest<CDDocumentAttachment> = CDDocumentAttachment.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error finding document: \(error)")
            return nil
        }
    }
    
    /// Save the managed object context
    private func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}