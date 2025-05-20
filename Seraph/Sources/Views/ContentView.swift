import SwiftUI
import Combine

public struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedItem: NavigationDestination? = .chats
    @State private var selectedConversation: UUID?
    @State private var selectedProject: UUID?
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $selectedItem,
                selectedConversation: $selectedConversation,
                selectedProject: $selectedProject
            )
            .environmentObject(appState)
            .frame(minWidth: 240, maxWidth: 280)
        } detail: {
            if let selectedItem = selectedItem {
                switch selectedItem {
                case .chat(let id):
                    if let conversation = appState.recentChats.first(where: { $0.id == id }) {
                        ChatView(conversation: conversation)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text("Conversation not found")
                            .foregroundColor(.secondary)
                    }
                case .project(let id):
                    if let project = appState.projects.first(where: { $0.id == id }) {
                        ProjectView(project: project)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text("Project not found")
                            .foregroundColor(.secondary)
                    }
                case .chats:
                    Text("Select a conversation")
                        .foregroundColor(.secondary)
                case .projects:
                    Text("Select a project")
                        .foregroundColor(.secondary)
                case .settings:
                    SettingsView()
                }
            } else {
                WelcomeView()
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .navigationTitle("Seraph")
        .onAppear {
            if appState.recentChats.isEmpty {
                appState.loadSampleData()
                if let firstChat = appState.recentChats.first {
                    selectedItem = .chat(id: firstChat.id)
                    selectedConversation = firstChat.id
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}
