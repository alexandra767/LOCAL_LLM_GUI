import SwiftUI

struct NewDocumentView: View {
    let viewModel: KnowledgeBaseViewModel
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var description: String = ""
    @State private var tags: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Document Details")) {
                    TextField("Title", text: $title)
                    
                    TextEditor(text: $content)
                        .frame(height: 200)
                    
                    TextField("Description", text: $description)
                    
                    TextField("Tags (comma separated)", text: $tags)
                }
            }
            .navigationTitle("New Document")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        // Create new document
                        viewModel.createDocument(
                            title: title,
                            content: content,
                            description: description,
                            tags: tags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
}