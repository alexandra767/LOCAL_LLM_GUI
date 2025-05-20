import SwiftUI
import Combine

// Import Seraph types
import class Seraph.AppState
import class Seraph.Project
import class Seraph.Conversation
import struct Seraph.ChatView
import struct Seraph.ProjectView
import struct Seraph.SettingsView
import struct Seraph.SidebarView
import enum Seraph.NavigationDestination

/// The main view of the application that contains the navigation split view
public struct MainView: View {
    @StateObject private var appState = AppState()
    @State private var selection: NavigationDestination? = nil
    @State private var selectedConversationId: UUID? = nil
    @State private var selectedProjectId: UUID? = nil
    
    public init() {
        // Initialize with default selection
        _selection = State(initialValue: .chats)
    }
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $selection,
                selectedConversationId: $selectedConversationId,
                selectedProjectId: $selectedProjectId
            )
            .environmentObject(appState)
        } detail: {
            NavigationStack {
                if let selection = selection {
                    switch selection {
                    case .chat(let id):
                        if let conversation = appState.recentChats.first(where: { $0.id == id }) {
                            ChatView(conversation: conversation)
                                .environmentObject(appState)
                        } else {
                            ContentUnavailableView("Conversation not found", systemImage: "bubble.left")
                        }
                    case .project(let id):
                        if let project = appState.projects.first(where: { $0.id == id }) {
                            ProjectView(project: Binding<Project>(
                                get: { project },
                                set: { _ in }
                            ), appState: appState)
                        } else {
                            ContentUnavailableView("Project not found", systemImage: "folder")
                        }
                    case .chats:
                        ContentUnavailableView("No Conversation Selected", systemImage: "bubble.left")
                    case .projects:
                        ContentUnavailableView("No Project Selected", systemImage: "folder")
                    case .settings:
                        SettingsView()
                    }
                } else {
                    ContentUnavailableView("Select an item from the sidebar", systemImage: "sidebar.left")
                }
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .environmentObject(appState)
        .onAppear {
            // Load sample data for preview if needed
            if appState.recentChats.isEmpty {
                // Initialize with a default conversation if none exists
                let conversation = appState.createNewConversation()
                selection = .chat(id: conversation.id)
                selectedConversationId = conversation.id
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

// MARK: - Preview

#Preview {
    let appState = AppState.preview
    return MainView()
        .environmentObject(appState)
}
