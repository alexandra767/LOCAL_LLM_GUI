import SwiftUI
import AppKit

struct DocumentPreviewView: View {
    @StateObject private var viewModel: DocumentPreviewViewModel
    
    init(document: DocumentAttachment) {
        _viewModel = StateObject(wrappedValue: DocumentPreviewViewModel(document: document))
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text(viewModel.document.name)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                if viewModel.document.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    viewModel.copyToClipboard()
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    viewModel.deleteDocument()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
}

#Preview {
    DocumentPreviewView(document: DocumentAttachment(
        name: "Sample Document",
        type: .text,
        content: "This is a sample document content. It can be text, markdown, or other content types.",
        metadata: [:]
    ))
}
