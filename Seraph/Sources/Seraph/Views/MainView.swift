import SwiftUI
import AppKit
import LLMService

@available(macOS 14.0, *)

/// The main container view that holds the application's UI structure.
/// This view manages the navigation and layout of the sidebar and content areas.
public struct MainView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selection: NavigationDestination? = nil
    @State private var selectedConversationId: UUID? = nil
    @State private var selectedProjectId: UUID? = nil
    
    public init() {}
    
    private func chatView(for id: UUID) -> AnyView {
        if let conversation = appState.conversations.first(where: { $0.id == id }) {
            AnyView(
                ChatView(
                    conversation: conversation,
                    llmService: appState.llmService
                )
                .environmentObject(appState)
            )
        } else {
            AnyView(
                ContentUnavailableView("Conversation not found", systemImage: "bubble.left")
            )
        }
    }
    
    private func projectView(for id: UUID) -> AnyView {
        if let project = appState.projects.first(where: { $0.id == id }) {
            AnyView(
                ProjectView(project: project)
                    .environmentObject(appState)
            )
        } else {
            AnyView(
                ContentUnavailableView("Project not found", systemImage: "folder")
            )
        }
    }
    
    private func detailView(for selection: NavigationDestination) -> AnyView {
        switch selection {
        case .chat(let id):
            chatView(for: id)
        case .project(let id):
            projectView(for: id)
        case .settings:
            AnyView(SettingsView())
        case .chats:
            AnyView(
                List(appState.conversations.filter { $0.projectId == nil }) { conversation in
                    Text(conversation.title)
                }
                .navigationTitle("Chats")
            )
        case .projects:
            AnyView(
                List(appState.projects) { project in
                    Text(project.name)
                }
                .navigationTitle("Projects")
            )
        }
    }
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $selection,
                appState: appState
            )
        } detail: {
            NavigationStack {
                if let selection = selection {
                    detailView(for: selection)
                } else {
                    ContentUnavailableView("Select a conversation or project", systemImage: "bubble.left")
                }
            }
        }
        .onAppear {
            if appState.conversations.isEmpty {
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
                        _ = appState.createNewConversation(title: "Sample Chat")
                        
                        let project = appState.createNewProject(
                            name: "Sample Project",
                            description: "A sample project"
                        )
                        
                        _ = appState.createNewConversation(
                            title: "Project Chat",
                            inProject: project.id
                        )
                    }
                }
        }
    }
}
