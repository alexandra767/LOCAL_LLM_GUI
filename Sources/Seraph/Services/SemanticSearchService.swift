import Foundation

@MainActor
class SemanticSearchService: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // Simplified version without NaturalLanguage framework
    private var documents: [String: SearchDocument] = [:]
    
    init() {
        loadDocuments()
    }
    
    func search(query: String, maxResults: Int = 5) async {
        isLoading = true
        defer { isLoading = false }
        
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        // Simple keyword-based search (instead of vector embeddings)
        var results: [(String, Double)] = []
        
        for (id, document) in documents {
            // Calculate a simple relevance score based on keyword frequency
            let lowerQuery = query.lowercased()
            let lowerContent = document.content.lowercased()
            let lowerTitle = document.title.lowercased()
            
            // Check if query appears in title or content
            if lowerTitle.contains(lowerQuery) || lowerContent.contains(lowerQuery) {
                let titleMatches = lowerTitle.components(separatedBy: lowerQuery).count - 1
                let contentMatches = lowerContent.components(separatedBy: lowerQuery).count - 1
                
                // Title matches are weighted more heavily
                let score = Double(titleMatches * 5 + contentMatches) / 100.0
                results.append((id, score))
            }
        }
        
        // Sort by score and get top results
        results.sort { $0.1 > $1.1 }
        searchResults = results.prefix(maxResults).map { result in
            let document = documents[result.0]!
            return SearchResult(
                id: document.id,
                title: document.title,
                content: document.content,
                similarity: result.1
            )
        }
        
        // If no matches found with the algorithm, just return the most recent documents
        if searchResults.isEmpty && !documents.isEmpty {
            searchResults = documents.values.prefix(maxResults).map { doc in
                SearchResult(
                    id: doc.id,
                    title: doc.title,
                    content: doc.content,
                    similarity: 0.1
                )
            }
        }
    }
    
    func addDocument(_ document: Document) {
        // Convert Document to SearchDocument
        let searchDoc = SearchDocument(
            id: document.id.uuidString,
            title: document.title,
            content: document.content,
            metadata: ["description": document.description]
        )
        
        documents[searchDoc.id] = searchDoc
    }
    
    func addDocument(_ document: SearchDocument) {
        documents[document.id] = document
    }
    
    func removeDocument(_ document: SearchDocument) {
        documents.removeValue(forKey: document.id)
    }
    
    func removeDocumentById(_ id: String) {
        documents.removeValue(forKey: id)
    }
    
    private func loadDocuments() {
        // Load from persistence
        // For now, using sample data
        let sampleDocument = Document(
            id: UUID(),
            title: "Sample Document",
            content: "This is a sample document containing some text that can be searched. It includes various topics and information that might be relevant to different queries.",
            description: "A sample document for testing search functionality"
        )
        addDocument(sampleDocument)
    }
}

struct SearchResult: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let similarity: Double
    
    var snippet: String {
        let maxChars = 100
        let content = self.content
        if content.count <= maxChars {
            return content
        }
        return String(content.prefix(maxChars)) + "..."
    }
}

struct SearchDocument: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let createdAt: Date
    let metadata: [String: String]
    
    init(id: String = UUID().uuidString, title: String, content: String, metadata: [String: String] = [:]) {
        self.id = id
        self.title = title
        self.content = content
        self.metadata = metadata
        self.createdAt = Date()
    }
}
