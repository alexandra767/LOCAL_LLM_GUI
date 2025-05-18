import Foundation

struct DocumentAttachment: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: DocumentType
    let content: String
    var metadata: [String: String]
    let createdAt: Date
    
    var isFavorite: Bool {
        metadata["isFavorite"] == "true"
    }
    
    init(id: UUID = UUID(), name: String, type: DocumentType, content: String, metadata: [String: String] = [:]) {
        self.id = id
        self.name = name
        self.type = type
        self.content = content
        self.metadata = metadata
        self.createdAt = Date()
    }
}
