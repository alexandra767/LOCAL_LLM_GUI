import SwiftUI

struct EditProjectView: View {
    let project: Project
    let viewModel: ProjectDetailViewModel
    
    @State private var name: String
    @State private var description: String
    @Environment(\.dismiss) private var dismiss
    
    init(project: Project, viewModel: ProjectDetailViewModel) {
        self.project = project
        self.viewModel = viewModel
        _name = State(initialValue: project.name)
        _description = State(initialValue: project.description)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Name", text: $name)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateProject(name: name, description: description)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}