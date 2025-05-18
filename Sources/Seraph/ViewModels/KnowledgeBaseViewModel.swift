import Foundation
import SwiftUI

struct Document: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var description: String
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date
    var isStarred: Bool
    
    init(id: UUID = UUID(), title: String, content: String, description: String, tags: [String] = [], isStarred: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.description = description
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isStarred = isStarred
    }
}

@MainActor
class KnowledgeBaseViewModel: ObservableObject {
    @Published var documents: [Document] = []
    @Published var showNewDocumentSheet = false
    
    init() {
        loadDocuments()
    }
    
    private func loadDocuments() {
        // Load from persistence
        // For now, using sample data
        documents = [
            Document(
                title: "Swift Best Practices",
                content: "# Swift Best Practices\n\n1. Use meaningful variable names\n2. Follow Swift naming conventions\n3. Use optionals properly\n...",
                description: "Guide to writing clean Swift code",
                tags: ["swift", "best-practices", "coding"]
            ),
            Document(
                title: "API Design",
                content: "# API Design Guidelines\n\n1. Use consistent naming\n2. Follow REST principles\n3. Use proper HTTP methods\n...",
                description: "Guide to RESTful API design",
                tags: ["api", "design", "rest"]
            )
        ]
    }
    
    func createDocument(title: String, content: String, description: String, tags: [String]) {
        let newDocument = Document(title: title, content: content, description: description, tags: tags)
        documents.append(newDocument)
        saveDocuments()
    }
    
    func updateDocument(_ document: Document, title: String, content: String, description: String, tags: [String]) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            var updatedDocument = document
            updatedDocument.title = title
            updatedDocument.content = content
            updatedDocument.description = description
            updatedDocument.tags = tags
            updatedDocument.updatedAt = Date()
            documents[index] = updatedDocument
            saveDocuments()
        }
    }
    
    func deleteDocuments(at offsets: IndexSet) {
        documents.remove(atOffsets: offsets)
        saveDocuments()
    }
    
    func toggleStar(for document: Document) {
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            var updatedDocument = document
            updatedDocument.isStarred.toggle()
            documents[index] = updatedDocument
            saveDocuments()
        }
    }
    
    private func saveDocuments() {
        // TODO: Implement persistence
        print("Saving documents")
    }
    
    func searchDocuments(_ query: String) -> [Document] {
        return documents.filter { document in
            document.title.lowercased().contains(query.lowercased()) ||
            document.description.lowercased().contains(query.lowercased()) ||
            document.tags.joined().lowercased().contains(query.lowercased())
        }
    }
    
    func getDocument(by id: UUID) -> Document? {
        documents.first { $0.id == id }
    }
}
