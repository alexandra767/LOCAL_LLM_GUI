import SwiftUI

struct ProjectDetailView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var projectViewModel: ProjectViewModel
    @StateObject private var viewModel: ProjectDetailViewModel
    @Environment(\.presentationMode) private var presentationMode
    
    init(project: Project) {
        _viewModel = StateObject(wrappedValue: ProjectDetailViewModel(project: project))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    // Close button
                    Button(action: {
                        projectViewModel.showProjectDetail = false
                        projectViewModel.selectedProject = nil
                    }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text(viewModel.project.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.showEditSheet = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.white)
                    }
                    Button(action: {
                        viewModel.showDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(red: 0.18, green: 0.18, blue: 0.18))
                
                // Project Info
                VStack(alignment: .leading, spacing: 16) {
                    Text(viewModel.project.description)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Created: \(viewModel.project.createdAt.formatted())")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(red: 0.18, green: 0.18, blue: 0.18))
                
                // Chats
                List {
                    ForEach(viewModel.chats) { chat in
                        NavigationLink {
                            ChatView(chat: chat)
                        } label: {
                            ChatRowView(chat: chat)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            viewModel.deleteChat(at: index)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            .sheet(isPresented: $viewModel.showEditSheet) {
                EditProjectView(project: viewModel.project, viewModel: viewModel)
            }
            .alert("Delete Project", isPresented: $viewModel.showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    viewModel.deleteProject()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.showDeleteAlert = false
                }
            } message: {
                Text("Are you sure you want to delete this project and all its chats?")
            }
        }
    }
}

struct ChatRowView: View {
    let chat: Chat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chat.title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text("\(chat.messages.count) messages")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    ProjectDetailView(project: Project(name: "Test Project"))
        .environmentObject(AppState())
}
