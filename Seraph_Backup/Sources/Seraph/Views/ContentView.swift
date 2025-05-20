import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedItem: NavigationItem? = .chats
    @State private var selectedConversation: ChatConversation.ID?
    @State private var selectedProject: Project.ID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: {
                SidebarView(
                    selection: $selectedItem,
                    selectedConversation: $selectedConversation,
                    selectedProject: $selectedProject
                )
                .frame(minWidth: 240, maxWidth: 280)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button(action: toggleSidebar) {
                            Image(systemName: "sidebar.left")
                        }
                    }
                }
            },
            content: {
                // Empty middle column (can be used for project contents)
                if let projectId = selectedProject,
                   let project = appState.projects.first(where: { $0.id == projectId }) {
                    ProjectView(project: project)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("Select a project to view details")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            },
            detail: {
                if let conversationId = selectedConversation,
                   let conversation = appState.recentChats.first(where: { $0.id == conversationId }) {
                    ChatView(conversation: conversation)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: Theme.Spacing.medium) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.Colors.secondaryText.opacity(0.5))
                        
                        Text("Start a new conversation")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.primaryText)
                        
                        Button(action: createNewChat) {
                            Label("New Chat", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding()
                                .background(Theme.Colors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        )
        .frame(minWidth: 1000, minHeight: 700)
        .onChange(of: selectedItem) { newValue in
            // Handle navigation item selection
            switch newValue {
            case .chat(let id):
                selectedConversation = id
            case .project(let id):
                selectedProject = id
            case .settings, .none:
                break
            }
        }
        .onAppear {
            // Set initial selection if needed
            if selectedItem == nil && !appState.recentChats.isEmpty {
                selectedItem = .chat(id: appState.recentChats[0].id)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject({
            let state = AppState()
            state.loadSampleData()
            return state
        }())
}
