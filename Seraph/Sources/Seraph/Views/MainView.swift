import SwiftUI
import AppKit

@available(macOS 14.0, *)

/// The main container view that holds the application's UI structure.
/// This view manages the navigation and layout of the sidebar and content areas.
public struct MainView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selection: NavigationDestination? = nil
    @State private var selectedConversationId: UUID? = nil
    @State private var selectedProjectId: UUID? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $selection,
                selectedConversationId: $selectedConversationId,
                selectedProjectId: $selectedProjectId
            )
        } detail: {
            NavigationStack {
                if let selection = selection {
                    switch selection {
                        case .chat(let id):
                            if let conversation = appState.recentChats.first(where: { $0.id == id }) {
                                ChatView(conversation: conversation)
                            } else {
                                ContentUnavailableView("Conversation not found", systemImage: "bubble.left")
                            }
                        case .project(let id):
                            if let project = appState.projects.first(where: { $0.id == id }) {
                                ProjectView(
                                    project: Binding(
                                        get: { project },
                                        set: { _ in }
                                    )
                                )
                                .environmentObject(appState)
                            } else {
                                ContentUnavailableView("Project not found", systemImage: "folder")
                            }
                        case .settings:
                            SettingsView()
                        case .chats:
                            // Show a list of all chats
                            if appState.recentChats.isEmpty {
                                ContentUnavailableView("No Chats", systemImage: "bubble.left")
                            } else {
                                List(appState.recentChats) { conversation in
                                    // Add chat list view here
                                    Text(conversation.title)
                                }
                                .navigationTitle("Chats")
                            }
                        case .projects:
                            // Show a list of all projects
                            if appState.projects.isEmpty {
                                ContentUnavailableView("No Projects", systemImage: "folder")
                            } else {
                                List(appState.projects) { project in
                                    // Add project list view here
                                    Text(project.name)
                                }
                                .navigationTitle("Projects")
                            }
                    }
                } else {
                    // Default empty state
                    ContentUnavailableView("Select a conversation or project", systemImage: "bubble.left")
                }
            }
        }
        .onAppear {
            // Load initial state if needed
            if appState.recentChats.isEmpty {
                Task {
                    appState.createNewConversation(title: "New Chat")
                }
            }
        }
        .onChange(of: selectedConversationId) { newValue in
            if let id = newValue {
                selection = .chat(id: id)
            }
        }
        .onChange(of: selectedProjectId) { newValue in
            if let id = newValue {
                selection = .project(id: id)
            }
        }
    }
}

// MARK: - Previews

@available(macOS 14.0, *)
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.preview
        
        // Create a preview container that properly sets up the environment
        PreviewContainer(appState: appState) {
            MainView()
                .frame(width: 1200, height: 800)
        }
    }
    
    private struct PreviewContainer<Content: View>: View {
        @StateObject var appState: AppState
        @State private var previewDataLoaded = false
        let content: () -> Content
        
        init(appState: AppState, @ViewBuilder content: @escaping () -> Content) {
            _appState = StateObject(wrappedValue: appState)
            self.content = content
        }
        
        var body: some View {
            content()
                .environmentObject(appState)
                .onAppear {
                    guard !previewDataLoaded else { return }
                    previewDataLoaded = true
                    
                    Task {
                        // Create a sample conversation
                        _ = appState.createNewConversation(title: "Sample Chat")
                        
                        // Create a sample project
                        let project = Project(
                            name: "Sample Project",
                            description: "A sample project"
                        )
                        _ = appState.createProject(title: project.name)
                        
                        // Create a conversation in the project
                        _ = appState.createNewConversation(
                            title: "Project Chat",
                            inProject: project.id
                        )
                    }
                }
        }
        

    }
}
