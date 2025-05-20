import SwiftUI
import AppKit

/// A view that displays the sidebar navigation for the app.
/// This includes chat history and project organization.

/// A view that displays the sidebar navigation for the app.
public struct SidebarView: View {
    @Binding public var selection: NavigationDestination?
    @Binding public var selectedConversationId: UUID?
    @Binding public var selectedProjectId: UUID?
    
    @EnvironmentObject private var appState: AppState
    @State private var isShowingNewProjectSheet = false
    @State private var newProjectName = ""
    
    public init(selection: Binding<NavigationDestination?>,
                selectedConversationId: Binding<UUID?>,
                selectedProjectId: Binding<UUID?>) {
        self._selection = selection
        self._selectedConversationId = selectedConversationId
        self._selectedProjectId = selectedProjectId
    }
    
    public var body: some View {
        List(selection: $selection) {
            Section("Chats") {
                ForEach(appState.recentChats) { conversation in
                    NavigationLink(value: NavigationDestination.chat(id: conversation.id)) {
                        Label(conversation.title, systemImage: "bubble.left")
                            .lineLimit(1)
                            .badge(conversation.unreadCount > 0 ? "\(conversation.unreadCount)" : nil)
                    }
                    .tag(NavigationDestination.chat(id: conversation.id))
                    .contextMenu {
                        Button(role: .destructive) {
                            appState.deleteConversation(withId: conversation.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                
                Button(action: {
                    Task { 
                        appState.createNewConversation()
                    }
                }) {
                    Label("New Chat", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            
            Section("Projects") {
                ForEach(appState.projects) { project in
                    NavigationLink(value: NavigationDestination.project(id: project.id)) {
                        Label(project.name, systemImage: "folder")
                            .lineLimit(1)
                    }
                    .tag(NavigationDestination.project(id: project.id))
                }
                
                Button(action: {
                    isShowingNewProjectSheet = true
                }) {
                    Label("New Project", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
            }
        }
        .sheet(isPresented: $isShowingNewProjectSheet) {
            newProjectSheet
        }
        .onChange(of: selection) { newValue in
            if case let .chat(id) = newValue {
                selectedConversationId = id
                selectedProjectId = nil
            } else if case let .project(id) = newValue {
                selectedProjectId = id
                selectedConversationId = nil
            }
        }
        .onAppear {
            // Select the first conversation by default if none is selected
            if selection == nil, let firstConversation = appState.recentChats.first {
                selection = .chat(id: firstConversation.id)
            }
        }
    }
    
    private var newProjectSheet: some View {
        NavigationView {
            Form {
                TextField("Project Name", text: $newProjectName)
                    .textFieldStyle(.roundedBorder)
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isShowingNewProjectSheet = false
                        newProjectName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { 
                            appState.createProject(title: newProjectName)
                            isShowingNewProjectSheet = false
                            newProjectName = ""
                        }
                    }
                    .disabled(newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .frame(width: 400, height: 200)
        }
    }
    
    private func toggleSidebar() {
        #if os(macOS)
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        #endif
    }
}

// MARK: - Previews

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.preview
        
        // For preview we use the preview state that already has data
        
        return SidebarView(
            selection: .constant(nil),
            selectedConversationId: .constant(nil),
            selectedProjectId: .constant(nil)
        )
        .environmentObject(appState)
        .frame(width: 250)
    }
}
