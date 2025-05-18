import Foundation
import UniformTypeIdentifiers

enum DocumentType: String, CaseIterable, Identifiable, Codable {
    case text = "text"
    case pdf = "pdf"
    case image = "image"
    case markdown = "markdown"
    
    var id: String { rawValue }
    
    var supportedExtensions: [String] {
        switch self {
        case .text: return ["txt", "md"]
        case .pdf: return ["pdf"]
        case .image: return ["jpg", "jpeg", "png", "gif", "webp"]
        case .markdown: return ["md", "markdown"]
        }
    }
}

extension DocumentType {
    var supportedFileTypes: [UTType] {
        switch self {
        case .text:
            return [.text, .plainText]
        case .pdf:
            return [.pdf]
        case .image:
            return [.jpeg, .png, .gif]
        case .markdown:
            return [.text]
        }
    }
    
    var fileExtensions: [String] {
        switch self {
        case .text: return ["txt", "md", "markdown"]
        case .pdf: return ["pdf"]
        case .image: return ["jpg", "jpeg", "png", "gif"]
        case .markdown: return ["md", "markdown"]
        }
    }
    
    func canProcessFile(_ url: URL) -> Bool {
        let pathExtension = url.pathExtension.lowercased()
        return fileExtensions.contains(pathExtension)
    }
    
    static func fromFileExtension(_ fileExtension: String) -> DocumentType? {
        for type in allCases {
            if type.fileExtensions.contains(fileExtension.lowercased()) {
                return type
            }
        }
        return nil
    }
    
    static func fromFileURL(_ url: URL) -> DocumentType? {
        return fromFileExtension(url.pathExtension)
    }
}
