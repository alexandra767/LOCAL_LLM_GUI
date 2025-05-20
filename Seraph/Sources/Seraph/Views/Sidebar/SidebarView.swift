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
    let destination: SidebarNavigationDestination
    
    public var body: some View {
        Label(title, systemImage: icon)
    }
    
    public init(title: String, icon: String, destination: SidebarNavigationDestination) {
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

// MARK: - AppState Extension

private extension AppState {
    var recentChats: [Conversation] {
        conversations
            .sorted(by: { $0.timestamp > $1.timestamp })
            .prefix(5)
            .map { $0 }
    }
    
    var recentProjects: [Project] {
        projects
            .sorted(by: { $0.lastUpdated > $1.lastUpdated })
            .prefix(5)
            .map { $0 }
    }
}

// MARK: - String Extension

extension String {
    func prefix(_ maxLength: Int) -> String {
        String(prefix(Swift.min(maxLength, count)))
    }
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
    public init(selection: Binding<NavigationDestination?>, appState: AppState = .shared) {
        self._selection = selection
        self.appState = appState
    }
    
    // MARK: - Private Properties
    
    private var recentChats: [Conversation] {
        appState.conversations
            .filter { $0.projectId == nil }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(5)
            .map { $0 }
    }
    
    private var recentProjects: [Project] {
        appState.projects
            .sorted { $0.lastUpdated > $1.lastUpdated }
            .prefix(5)
            .map { $0 }
    }
    
    // MARK: - Private Methods
    
    private func createNewConversation() {
        let conversation = Conversation(title: "New Chat")
        appState.conversations.append(conversation)
        selection = .chat(id: conversation.id)
    }
    
    private func createProject(name: String) {
        let project = Project(name: name)
        appState.projects.append(project)
        selection = .project(id: project.id)
    }
    
    private func deleteConversation(_ conversation: Conversation) {
        Task { @MainActor in
            if let index = appState.conversations.firstIndex(where: { $0.id == conversation.id }) {
                appState.conversations.remove(at: index)
                
                // Clear selection if the deleted conversation was selected
                if case .chat(let id) = selection, id == conversation.id {
                    selection = nil
                }
            }
        }
    }
    
    private func deleteProject(_ project: Project) {
        Task { @MainActor in
            if let index = appState.projects.firstIndex(where: { $0.id == project.id }) {
                appState.projects.remove(at: index)
                
                // Clear selection if the deleted project was selected
                if case .project(let id) = selection, id == project.id {
                    selection = nil
                }
            }
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
                ForEach(recentChats) { conversation in
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
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: toggleSidebar) {
                    Label("Toggle Sidebar", systemImage: "sidebar.left")
                }
            }
        }
        .sheet(isPresented: $isShowingNewProjectSheet) {
            NewProjectView(isPresented: $isShowingNewProjectSheet) { name in
                createProject(name: name)
            }
        }
        .onAppear {
            // Select the first conversation by default if none is selected
            if selection == nil, let firstConversation = recentChats.first {
                selection = .chat(id: firstConversation.id)
            }
        }
    }
}

// MARK: - New Project View

private struct NewProjectView: View {
    @Binding var isPresented: Bool
    let onCreate: (String) -> Void
    @State private var projectName: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("New Project")
                .font(.headline)
            
            TextField("Project Name", text: $projectName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Create") {
                    if !projectName.isEmpty {
                        onCreate(projectName)
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(projectName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

// MARK: - Previews

#Preview(traits: .fixedLayout(width: 250, height: 600)) {
    // Create a mock AppState for preview
    let appState = AppState.shared
    
    // Add sample data for preview using the public API
    let conversation1 = Conversation(title: "Sample Chat 1")
    let conversation2 = Conversation(title: "Sample Chat 2")
    appState.addConversation(conversation1)
    appState.addConversation(conversation2)
    
    let project1 = Project(name: "Project 1")
    let project2 = Project(name: "Project 2")
    appState.addProject(project1)
    appState.addProject(project2)
    
    SidebarView(
        selection: .constant(.chat(id: conversation1.id)),
        appState: appState
    )
    .frame(width: 250)
}
