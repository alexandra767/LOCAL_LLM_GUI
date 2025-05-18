import SwiftUI

struct KnowledgeBaseView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = KnowledgeBaseViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Knowledge Base")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    
                    Button(action: {
                        viewModel.showNewDocumentSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                // Document List
                List {
                    ForEach(viewModel.documents) { document in
                        NavigationLink {
                            DocumentDetailView(document: document)
                        } label: {
                            DocumentRowView(document: document)
                        }
                    }
                    .onDelete { indexSet in
                        viewModel.deleteDocuments(at: indexSet)
                    }
                }
                .listStyle(.plain)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .background(Color(red: 0.1176, green: 0.1176, blue: 0.1176))
            .sheet(isPresented: $viewModel.showNewDocumentSheet) {
                NewDocumentView(viewModel: viewModel)
            }
        }
    }
}

struct DocumentRowView: View {
    let document: Document
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(document.title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(document.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)
            
            HStack {
                Text("\(document.tags.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(document.createdAt.formatted())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    KnowledgeBaseView()
        .environmentObject(AppState())
}
