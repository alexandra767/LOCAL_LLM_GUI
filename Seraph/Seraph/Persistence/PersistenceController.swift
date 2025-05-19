//
//  PersistenceController.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import CoreData

struct PersistenceController {
    // MARK: - Shared Instance
    static let shared = PersistenceController()
    
    // MARK: - Preview Instance
    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        createSampleData(in: viewContext)
        
        return result
    }()
    
    // MARK: - Properties
    let container: NSPersistentContainer
    
    // MARK: - Initialization
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Seraph")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Helper Methods
    
    /// Create sample data for previews
    @MainActor
    private static func createSampleData(in context: NSManagedObjectContext) {
        // Create sample user
        let userEntity = CDUser(context: context)
        userEntity.id = UUID()
        userEntity.name = "Sample User"
        userEntity.email = "user@example.com"
        userEntity.createdAt = Date()
        
        // Create sample preferences
        let preferencesEntity = CDUserPreferences(context: context)
        preferencesEntity.id = UUID()
        preferencesEntity.isDarkMode = true
        preferencesEntity.accentColor = "#FF643D"
        preferencesEntity.fontSize = "medium"
        preferencesEntity.defaultModel = "ollama-Mistral 7B"
        preferencesEntity.defaultSystemPrompt = "You are a helpful AI assistant."
        preferencesEntity.defaultTemperature = 0.7
        preferencesEntity.defaultMaxTokens = 2048
        preferencesEntity.user = userEntity
        
        // Create sample project
        let projectEntity = CDProject(context: context)
        projectEntity.id = UUID()
        projectEntity.name = "Sample Project"
        projectEntity.projectDescription = "This is a sample project for testing."
        projectEntity.createdAt = Date()
        projectEntity.updatedAt = Date()
        projectEntity.isPinned = true
        projectEntity.color = "#FF643D"
        
        // Create sample system prompt
        let systemPromptEntity = CDSystemPrompt(context: context)
        systemPromptEntity.id = UUID()
        systemPromptEntity.name = "Default Assistant"
        systemPromptEntity.content = "You are a helpful AI assistant."
        systemPromptEntity.isDefault = true
        systemPromptEntity.createdAt = Date()
        
        // Create sample chat
        let chatEntity = CDChat(context: context)
        chatEntity.id = UUID()
        chatEntity.title = "Sample Chat"
        chatEntity.createdAt = Date()
        chatEntity.updatedAt = Date()
        chatEntity.model = "ollama-Mistral 7B"
        chatEntity.systemPrompt = "You are a helpful AI assistant."
        chatEntity.isPinned = false
        chatEntity.project = projectEntity
        
        // Create sample messages
        let userMessageEntity = CDMessage(context: context)
        userMessageEntity.id = UUID()
        userMessageEntity.content = "Hello, I need help with Swift programming."
        userMessageEntity.role = "User"
        userMessageEntity.timestamp = Date(timeIntervalSinceNow: -300) // 5 minutes ago
        userMessageEntity.isComplete = true
        userMessageEntity.tokenCount = 10
        userMessageEntity.chat = chatEntity
        
        let assistantMessageEntity = CDMessage(context: context)
        assistantMessageEntity.id = UUID()
        assistantMessageEntity.content = "Hi there! I'd be happy to help you with Swift programming. What specific questions or issues do you have?"
        assistantMessageEntity.role = "Assistant"
        assistantMessageEntity.timestamp = Date(timeIntervalSinceNow: -240) // 4 minutes ago
        assistantMessageEntity.isComplete = true
        assistantMessageEntity.tokenCount = 22
        assistantMessageEntity.chat = chatEntity
        
        // Save context
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    /// Save changes if context has changes
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Context Helpers
extension NSManagedObjectContext {
    
    /// Fetch all objects of a given type
    func fetchAll<T: NSManagedObject>(_ type: T.Type) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        do {
            return try fetch(request)
        } catch {
            print("Error fetching \(type): \(error)")
            return []
        }
    }
    
    /// Fetch objects with a predicate
    func fetch<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, limit: Int? = nil) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            return try fetch(request)
        } catch {
            print("Error fetching \(type): \(error)")
            return []
        }
    }
    
    /// Delete objects matching a predicate
    func delete<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: type))
        request.predicate = predicate
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try execute(batchDeleteRequest) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
            }
        } catch {
            print("Error deleting \(type): \(error)")
        }
    }
    
    /// Find an object by ID
    func find<T: NSManagedObject>(_ type: T.Type, id: UUID) -> T? {
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let results = fetch(type, predicate: predicate, limit: 1)
        return results.first
    }
    
    /// Perform a block on a background context
    static func perform<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) throws -> T {
        let context = PersistenceController.shared.container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        var result: T?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        context.perform {
            do {
                result = try block(context)
                if context.hasChanges {
                    try context.save()
                }
            } catch let e {
                error = e
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let error = error {
            throw error
        }
        
        return result!
    }
}