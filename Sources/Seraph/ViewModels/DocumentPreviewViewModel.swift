import Foundation
import SwiftUI

@MainActor
class DocumentPreviewViewModel: ObservableObject {
    @Published var document: DocumentAttachment {
        didSet {
            // Update favorite state when document changes
            isFavorite = document.metadata["isFavorite"] == "true"
        }
    }
    @Published var isFavorite: Bool = false
    @Published var isProcessing: Bool = false
    @Published var error: Error?
    
    private let searchService: SemanticSearchService
    
    init(document: DocumentAttachment) {
        self.document = document
        self.searchService = SemanticSearchService()
        
        // Initialize with default values
        self.isFavorite = document.metadata["isFavorite"] == "true"
    }
    
    func toggleFavorite() {
        isProcessing = true
        defer { isProcessing = false }
        
        // Create a new document with updated metadata
        var updatedDocument = document
        updatedDocument.metadata["isFavorite"] = isFavorite ? "false" : "true"
        self.document = updatedDocument
        isFavorite = !isFavorite
        
        // Convert to SearchDocument
        let searchDoc = SearchDocument(
            id: document.id.uuidString,
            title: document.name,
            content: document.content,
            metadata: document.metadata
        )
        
        // Update document in search service
        searchService.removeDocument(searchDoc)
        searchService.addDocument(searchDoc)
    }
    
    func shareDocument() {
        let shareContent: String
        switch document.type {
        case .image:
            if let imageData = document.content.data(using: .utf8),
               let _ = NSImage(data: imageData) {
                // Image is valid but we're just sharing text content anyway
                shareContent = "\(document.name)\n\n\(document.content)"
            } else {
                shareContent = document.name
            }
        default:
            shareContent = document.content
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(shareContent, forType: .string)
        
        NSWorkspace.shared.open(URL(string: "message://")!)
    }
    
    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch document.type {
        case .image:
            if let imageData = document.content.data(using: .utf8),
               let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            }
        default:
            pasteboard.setString(document.content, forType: .string)
        }
    }
    
    func deleteDocument() {
        isProcessing = true
        defer { isProcessing = false }
        
        // Convert to SearchDocument
        let searchDoc = SearchDocument(
            id: document.id.uuidString,
            title: document.name,
            content: document.content,
            metadata: document.metadata
        )
        
        searchService.removeDocument(searchDoc)
        // TODO: Remove from other storage locations
    }
    
    func exportDocument(to format: ExportFormat) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(document.name).\(format.rawValue)"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        switch format {
        case .txt:
            try document.content.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        case .html:
            try "<!DOCTYPE html>\n<html>\n<head>\n<title>\(document.name)</title>\n</head>\n<body>\n\(document.content)\n</body>\n</html>".write(to: fileURL, atomically: true, encoding: .utf8)
        case .pdf:
            // TODO: Implement PDF export
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "PDF export not implemented"])
        case .json:
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(document).write(to: fileURL)
        case .markdown:
            try document.content.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        }
        
        return fileURL
    }
}
