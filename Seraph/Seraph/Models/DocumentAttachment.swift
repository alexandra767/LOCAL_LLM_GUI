//
//  DocumentAttachment.swift
//  Seraph
//
//  Created by Alexandra Titus on 5/18/25.
//

import Foundation
import CoreData

/// A document or file attached to a message
struct DocumentAttachment: Identifiable, Codable, Equatable {
    /// Unique identifier for the attachment
    var id: UUID = UUID()
    
    /// Name of the document
    var name: String
    
    /// Type of document 
    var type: DocumentType
    
    /// URL for the document (can be local or remote)
    var url: URL?
    
    /// Content of the document
    var content: String?
    
    /// Initialize a new document attachment
    init(id: UUID = UUID(), name: String, type: DocumentType, url: URL? = nil, content: String? = nil, fileSize: Int64? = nil, createdAt: Date = Date(), preview: String? = nil, tokenCount: Int? = nil, fileExtension: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.url = url
        self.content = content
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.preview = preview
        self.tokenCount = tokenCount
        self.fileExtension = fileExtension
    }
    
    /// Size of the document in bytes
    var fileSize: Int64?
    
    /// Date the document was added
    var createdAt: Date = Date()
    
    /// Preview of the document content
    var preview: String?
    
    /// Token count for document
    var tokenCount: Int?
    
    /// File extension
    var fileExtension: String?
    
    /// Size of the document in a formatted string
    var formattedSize: String {
        guard let size = fileSize else { return "Unknown size" }
        
        // Convert to MB or KB
        if size > 1_048_576 {
            let mbSize = Double(size) / 1_048_576
            return String(format: "%.1f MB", mbSize)
        } else if size > 1024 {
            let kbSize = Double(size) / 1024
            return String(format: "%.1f KB", kbSize)
        } else {
            return "\(size) bytes"
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: DocumentAttachment, rhs: DocumentAttachment) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.type == rhs.type &&
               lhs.url == rhs.url &&
               lhs.content == rhs.content &&
               lhs.fileSize == rhs.fileSize &&
               lhs.createdAt == rhs.createdAt &&
               lhs.preview == rhs.preview &&
               lhs.tokenCount == rhs.tokenCount &&
               lhs.fileExtension == rhs.fileExtension
    }
}

/// Types of documents that can be attached
enum DocumentType: String, Codable, CaseIterable {
    case text = "Text"
    case code = "Code"
    case image = "Image"
    case pdf = "PDF"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .image: return "photo"
        case .pdf: return "doc.viewfinder"
        case .other: return "doc"
        }
    }
    
    var description: String {
        self.rawValue
    }
}

// Document extension methods are in CoreDataExtensions.swift