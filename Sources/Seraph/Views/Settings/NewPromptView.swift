import SwiftUI

struct NewPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SystemPromptViewModel
    
    @State private var name = ""
    @State private var description = ""
    @State private var content = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Prompt")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("New Prompt")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Create") {
                        viewModel.createPrompt(name: name, description: description, content: content)
                        dismiss()
                    }
                }
            }
        }
    }
}
