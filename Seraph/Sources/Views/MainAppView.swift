import SwiftUI

// MARK: - Main App View

/// The main view of the Seraph application.
public struct MainAppView: View {
    @StateObject private var appState = AppState.shared
    @State private var selectedConversationId: UUID?
    @State private var selectedProjectId: UUID?
    @State private var navigationPath = NavigationPath()
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $appState.selectedNavigation,
                selectedConversationId: $selectedConversationId,
                selectedProjectId: $selectedProjectId
            )
            .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
        } detail: {
            NavigationStack(path: $navigationPath) {
                Group {
                    if let conversationId = selectedConversationId,
                       let conversation = appState.conversation(with: conversationId) {
                        ChatView(conversation: conversation)
                    } else if let projectId = selectedProjectId,
                              let project = appState.project(with: projectId) {
                        ProjectView(project: project)
                    } else {
                        WelcomeView()
                    }
                }
                .navigationDestination(for: Conversation.self) { conversation in
                    if let conversation = appState.conversation(with: conversation.id) {
                        ChatView(conversation: conversation)
                    }
                }
                .navigationDestination(for: Project.self) { project in
                    if let project = appState.project(with: project.id) {
                        ProjectView(project: project)
                    }
                }
            }
        }
        .withTheme()
        .environmentObject(appState)
        .onAppear {
            // Ensure we have at least one conversation
            if appState.recentChats.isEmpty {
                Task { @MainActor in
                    await appState.createNewConversation()
                }
            }
        }
    }
}

// MARK: - Welcome View

private struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Welcome to Seraph")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Get started by creating a new chat or project")
                .foregroundColor(.secondary)
            
            Button(action: {
                Task { @MainActor in
                    await appState.createNewConversation()
                }
            }) {
                Label("New Chat", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Previews

#if DEBUG
struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
            .environmentObject(AppState.preview)
            .frame(width: 1000, height: 700)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(AppState())
            .frame(width: 600, height: 400)
    }
}
#endif
