import SwiftUI

struct DocumentDetailView: View {
    let document: Document
    @StateObject private var viewModel = DocumentDetailViewModel()
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text(document.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                
                Button(action: {
                    viewModel.toggleFavorite()
                }) {
                    Image(systemName: document.isStarred ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
                
                Button(action: {
                    viewModel.shareDocument()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    viewModel.exportDocument()
                }) {
                    Image(systemName: "arrow.down.doc")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(document.content)
                        .padding()
                }
                .padding()
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .background(Color(red: 0.1176, green: 0.1176, blue: 0.1176))
    }
}

class DocumentDetailViewModel: ObservableObject {
    @Published var isFavorite: Bool = false
    
    func toggleFavorite() {
        // Would update document favorite status in a real implementation
        isFavorite.toggle()
    }
    
    func shareDocument() {
        // Would implement document sharing functionality in a real implementation
        print("Share document")
    }
    
    func exportDocument() {
        // Would implement document export functionality in a real implementation
        print("Export document")
    }
}

#Preview {
    DocumentDetailView(document: Document(
        title: "Sample Document",
        content: "This is a sample document content.",
        description: "Sample description",
        tags: ["tag1", "tag2"]
    ))
}