import Foundation

enum ExportFormat: String, CaseIterable, Identifiable {
    case txt = "txt"
    case html = "html"
    case pdf = "pdf"
    case markdown = "markdown"
    case json = "json"
    
    var id: String { rawValue }
    
    var fileExtension: String { rawValue }
}
