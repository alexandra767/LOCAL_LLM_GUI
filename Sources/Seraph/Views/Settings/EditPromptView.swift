import SwiftUI
import Foundation

struct EditPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SystemPromptViewModel
    let prompt: SystemPrompt
    
    @State private var name: String = ""
    @State private var content: String = ""
    
    init(prompt: SystemPrompt, viewModel: SystemPromptViewModel) {
        self.prompt = prompt
        self.viewModel = viewModel
        _name = State(initialValue: prompt.name)
        _content = State(initialValue: prompt.content)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Prompt Details")) {
                    TextField("Name", text: $name)
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Edit Prompt")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        viewModel.updatePrompt(prompt, name: name, description: prompt.description, content: content)
                        dismiss()
                    }
                }
            }
        }
    }
}
