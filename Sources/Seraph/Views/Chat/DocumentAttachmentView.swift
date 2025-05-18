import SwiftUI
import Foundation
import AppKit

struct DocumentAttachmentView: View {
    let attachment: DocumentAttachment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(attachment.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                
                if let sizeString = attachment.metadata["size"], 
                   let size = Int64(sizeString) {
                    Text("\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Preview
            switch attachment.type {
            case .image:
                if let imageData = attachment.content.data(using: .utf8),
                   let image = NSImage(data: imageData) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                }
            case .pdf:
                Text("PDF Document")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            case .text, .markdown:
                Text(attachment.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            }
            
            // Metadata
            let metadata = attachment.metadata
            ForEach(Array(metadata.keys), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(metadata[key] ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
        .cornerRadius(12)
    }
}

#Preview {
    DocumentAttachmentView(attachment: DocumentAttachment(
        name: "example.pdf",
        type: .pdf,
        content: "Sample PDF content",
        metadata: ["size": "1024"]
    ))
}
