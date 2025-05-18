import Foundation

class ExportManager {
    static func exportChat(_ chat: Chat, format: ExportFormat) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "chat_\(chat.id.uuidString).\(format.fileExtension)"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        switch format {
        case .markdown:
            // Generate markdown format
            var content = "# \(chat.title)\n\n"
            content += "Created: \(chat.createdAt.formatted())\n\n"
            
            for message in chat.messages {
                content += "\n## \(message.role.rawValue)\n\n"
                content += "\(message.content)\n\n"
                content += "---\n"
            }
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        case .html:
            var content = ""
            content += "<!DOCTYPE html>"
            content += "<html>"
            content += "<head>"
            content += "<style>"
            content += "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif; }"
            content += ".message { margin: 1em 0; padding: 1em; border-radius: 8px; }"
            content += ".user { background-color: #f4f4f4; }"
            content += ".assistant { background-color: #e3e3e3; }"
            content += "</style>"
            content += "</head>"
            content += "<body>"
            content += "<h1>\(chat.title)</h1>"
            content += "<p>Created: \(chat.createdAt.formatted())</p>"
            
            for message in chat.messages {
                content += "<div class='message \(message.role.rawValue)'>"
                content += "<strong>\(message.role.rawValue)</strong>: \(message.content)"
                content += "</div>"
            }
            
            content += "</body>"
            content += "</html>"
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        case .pdf:
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "PDF export not implemented"])
        case .json:
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(chat).write(to: fileURL)
        case .txt:
            var content = ""
            content += "# \(chat.title)\n\n"
            content += "Created: \(chat.createdAt.formatted())\n\n"
            
            for message in chat.messages {
                content += "\n## \(message.role.rawValue)\n\n"
                content += "\(message.content)\n\n"
                content += "---\n"
            }
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        return fileURL
    }
}
