import SwiftUI
import AppKit
import Combine

// MARK: - Type Aliases
// MARK: - Navigation Types

/// Represents a navigation item in the sidebar
public struct NavigationItem: View, Identifiable {
    public let id = UUID()
    let title: String
    let icon: String
    let destination: NavigationDestination
    
    public var body: some View {
        Label(title, systemImage: icon)
    }
    
    public init(title: String, icon: String, destination: NavigationDestination) {
        self.title = title
        self.icon = icon
        self.destination = destination
    }
}

/// Represents the navigation destination in the sidebar
public enum SidebarNavigationDestination: Hashable {
    case chat(id: UUID)
    case project(id: UUID)
    case settings
    
    public static func == (lhs: SidebarNavigationDestination, rhs: SidebarNavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.chat(let lhsId), .chat(let rhsId)):
            return lhsId == rhsId
        case (.project(let lhsId), .project(let rhsId)):
            return lhsId == rhsId
        case (.settings, .settings):
            return true
        default:
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .chat(let id):
            hasher.combine("chat")
            hasher.combine(id)
        case .project(let id):
            hasher.combine("project")
            hasher.combine(id)
        case .settings:
            hasher.combine("settings")
        }
    }
}

extension Color {
    static let sidebarBackground = Color(NSColor.controlBackgroundColor)
    static let sidebarText = Color(NSColor.textColor)
}

// MARK: - Sidebar View

/// A view that displays the sidebar navigation for the app.
public struct SidebarView: View {
    // MARK: - Properties
    
    /// The currently selected navigation destination
    @Binding public var selection: NavigationDestination?
    
    /// The app state that contains the data for the view
    @ObservedObject private var appState: AppState
    
    @State private var isShowingNewProjectSheet = false
    
    // MARK: - Initialization
    
    /// Creates a new sidebar view with the specified selection and app state.
    init(selection: Binding<NavigationDestination?>, appState: AppState) {
        self._selection = selection
        self.appState = appState
    }
    
    // MARK: - Private Properties
    
    private var filteredRecentChats: [Conversation] {
        Array(appState.conversations
            .filter { $0.projectId == nil }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(5))
    }
    
    private var recentProjects: [Project] {
        Array(appState.projects
            .sorted { $0.lastUpdated > $1.lastUpdated }
            .prefix(5))
    }
    
    // MARK: - Private Methods
    
    private func createNewConversation() {
        let newConversation = appState.createNewConversation()
        selection = .chat(id: newConversation.id)
    }
    
    private func createProject(name: String) {
        let project = appState.createNewProject(name: name)
        selection = .project(id: project.id)
    }
    
    private func deleteConversation(_ conversation: Conversation) {
        appState.deleteConversation(withId: conversation.id)
        if case .chat(let id) = selection, id == conversation.id {
            selection = nil
        }
    }
    
    private func deleteProject(_ project: Project) {
        appState.deleteProject(project)
        
        // Clear selection if the deleted project was selected
        if case .project(let id) = selection, id == project.id {
            selection = nil
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(
            #selector(NSSplitViewController.toggleSidebar(_:)),
            with: nil
        )
    }
    
    // MARK: - Body
    
    public var body: some View {
        List(selection: $selection) {
            // Chats Section
            Section(header: Text("Recent Chats")) {
                ForEach(filteredRecentChats) { conversation in
                    NavigationLink(value: NavigationDestination.chat(id: conversation.id)) {
                        Label(conversation.title, systemImage: "bubble.left.fill")
                    }
                    .tag(NavigationDestination.chat(id: conversation.id))
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteConversation(conversation)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                
                Button(action: createNewConversation) {
                    Label("New Chat", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            
            // Projects Section
            Section(header: Text("Projects")) {
                ForEach(recentProjects) { project in
                    NavigationLink(value: NavigationDestination.project(id: project.id)) {
                        Label(project.name, systemImage: "folder.fill")
                    }
                    .tag(NavigationDestination.project(id: project.id))
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteProject(project)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                
                Button(action: { isShowingNewProjectSheet = true }) {
                    Label("New Project", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            
            // Settings Section
            Section {
                NavigationLink(value: NavigationDestination.settings) {
                    Label("Settings", systemImage: "gear")
                }
                .tag(NavigationDestination.settings)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .sheet(isPresented: $isShowingNewProjectSheet) {
            NewProjectSheet(isPresented: $isShowingNewProjectSheet, onCreate: createProject)
        }
    }
}

// MARK: - New Project Sheet

private struct NewProjectSheet: View {
    @Binding var isPresented: Bool
    let onCreate: (String) -> Void
    @State private var projectName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Project Name", text: $projectName)
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if !projectName.isEmpty {
                            onCreate(projectName)
                            isPresented = false
                        }
                    }
                }
            }
        }
        .frame(minWidth: 300, minHeight: 150)
    }
}

// MARK: - Previews

#if DEBUG
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(selection: .constant(nil), appState: AppState.preview)
            .frame(width: 250)
    }
}
#endif
