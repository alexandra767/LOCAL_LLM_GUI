import SwiftUI
import Combine

// Models and services are in the same module, no need to import them

@MainActor
public final class ProjectViewModel: ObservableObject, Sendable {
    @Published var isEditing = false
    @Published var newConversationTitle = ""
    @Published var showingNewConversationSheet = false
    @Published var showingDeleteConfirmation = false
    
    let project: Project
    let appState: AppState
    
    init(project: Project, appState: AppState) {
        self.project = project
        self.appState = appState
    }
    
    func createNewConversation() -> Conversation {
        let conversation = appState.createNewConversation(
            title: newConversationTitle.isEmpty ? "New Conversation" : newConversationTitle,
            inProject: project.id
        )
        appState.saveState()
        return conversation
    }
    
    func deleteConversation(at offsets: IndexSet) {
        let projectId = project.id
        let conversations = appState.conversations.filter { $0.projectId == projectId }
        
        for index in offsets {
            guard index < conversations.count else { continue }
            appState.deleteConversation(withId: conversations[index].id)
        }
        appState.saveState()
    }
    
    func deleteProject() {
        appState.deleteProject(withId: project.id)
        appState.saveState()
    }
    
    func selectConversation(_ conversationId: String) {
        appState.selectedConversationId = conversationId
    }
    
    func moveConversation(from source: IndexSet, to destination: Int) {
        // Implement conversation moving logic here
    }
}

/// A view that displays the details of a project and its related conversations
public struct ProjectView: View {
    @StateObject private var viewModel: ProjectViewModel
    
    public init(project: Project) {
        _viewModel = StateObject(wrappedValue: ProjectViewModel(project: project, appState: AppState.shared))
    }
    
    private func createNewConversation() -> Conversation {
        let conversation = viewModel.createNewConversation()
        // Update the selected conversation ID through the view model
        viewModel.selectConversation(conversation.id)
        return conversation
    }
    
    private func deleteConversation(at offsets: IndexSet) {
        viewModel.deleteConversation(at: offsets)
    }
    
    private var projectConversations: [Conversation] {
        viewModel.appState.conversations.filter { $0.projectId == viewModel.project.id }
    }
    
    @MainActor
    private func moveConversation(from source: IndexSet, to destination: Int) {
        viewModel.moveConversation(from: source, to: destination)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Project header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if viewModel.isEditing {
                        TextField("Project Name", text: $project.name)
                            .font(.title2.bold())
                            .textFieldStyle(.plain)
                    } else {
                        Text(project.name)
                            .font(.title2.bold())
                    }
                    
                    Spacer()
                    
                    Button(action: { viewModel.isEditing.toggle() }) {
                        Image(systemName: viewModel.isEditing ? "checkmark.circle.fill" : "pencil")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(role: .destructive, action: { viewModel.showingDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog(
                        "Delete Project",
                        isPresented: $viewModel.showingDeleteConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteProject()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to delete this project? This action cannot be undone.")
                    }
                }
                
                if viewModel.isEditing {
                    TextEditor(text: $project.description)
                        .frame(height: 80)
                        .padding(4)
                        .background(Color(.textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else if !project.description.isEmpty {
                    Text(project.description)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack {
                    Text("\(projectConversations.count) conversations")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("Created: \(project.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(10)
            .padding()
            
            Divider()
            
            // Conversations list
            List {
                if projectConversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No conversations yet")
                            .font(.headline)
                        Text("Create a new conversation to get started")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ForEach(projectConversations) { conversation in
                        NavigationLink(value: conversation) {
                            ConversationRow(conversation: conversation)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteConversation(conversation)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.showingNewConversationSheet = true }) {
                    Label("New Conversation", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingNewConversationSheet) {
            NavigationStack {
                Form {
                    TextField("Conversation Title", text: $viewModel.newConversationTitle)
                }
                .navigationTitle("New Conversation")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.showingNewConversationSheet = false
                            viewModel.newConversationTitle = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            let conversation = viewModel.createNewConversation()
                            viewModel.appState.selectedConversationId = conversation.id
                            viewModel.showingNewConversationSheet = false
                            viewModel.newConversationTitle = ""
                        }
                        .disabled(viewModel.newConversationTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .frame(minWidth: 400, minHeight: 200)
        }
    }
}

// MARK: - Previews

#Preview("With Conversations") {
    let appState = AppState.shared
    let project = Project(
        name: "Sample Project",
        description: "This is a sample project with some conversations."
    )
    
    // Create project data setup
    // Task {
    //     await appState.createProject(title: project.name)
    //     _ = await appState.createNewConversation(title: "Sample Conversation 1", systemPrompt: "", inProject: project.id)
    //     _ = await appState.createNewConversation(title: "Sample Conversation 2", systemPrompt: "", inProject: project.id)
    // }
    
    ProjectView(project: .constant(project), appState: appState)
        .environmentObject(appState)
}

#Preview("Empty Project") {
    let appState = AppState.shared
    let project = Project(
        name: "Empty Project",
        description: "This project has no conversations yet."
    )
    
    // Project data setup for preview
    // Task {
    //     await appState.createProject(title: project.name)
    // }
    
    ProjectView(project: .constant(project), appState: appState)
        .environmentObject(appState)
}
