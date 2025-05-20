import SwiftUI

// MARK: - Sidebar Section

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case chats, projects, settings
    
    var id: String { self.rawValue }
}

// MARK: - Navigation Item

enum NavigationItem: Hashable {
    case chat(id: UUID)
    case project(id: UUID)
    case settings
    
    var id: String {
        switch self {
        case .chat(let id):
            return "chat_\(id.uuidString)"
        case .project(let id):
            return "project_\(id.uuidString)"
        case .settings:
            return "settings"
        }
    }
    
    static var chats: NavigationItem { .chat(id: UUID()) }
    static var projects: NavigationItem { .project(id: UUID()) }
}

// MARK: - Sidebar View

struct SidebarView: View {
    // MARK: - Properties
    
    @EnvironmentObject private var appState: AppState
    @State private var newProjectName = ""
    @State private var showNewProjectSheet = false
    @State private var expandedSections: Set<SidebarSection> = [.chats, .projects]
    @Binding var selection: NavigationItem?
    @State private var searchText = ""
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // App Header
            appHeader
            
            // Search Bar
            searchBar
            
            // Main Content
            ScrollView {
                VStack(spacing: 0) {
                    // Recent Chats Section
                    if !appState.recentChats.isEmpty {
                        collapsibleSection(
                            section: .chats,
                            header: "RECENT CHATS",
                            icon: "bubble.left.fill"
                        ) {
                            ForEach(appState.recentChats.prefix(5)) { chat in
                                chatRow(chat: chat)
                            }
                        }
                    }
                    
                    // Projects Section
                    collapsibleSection(
                        section: .projects,
                        header: "PROJECTS",
                        icon: "folder"
                    ) {
                        // Add Project Button
                        Button(action: { showNewProjectSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Theme.Colors.accent)
                                Text("New Project")
                                    .foregroundColor(Theme.Colors.accent)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 4)
                        
                        // Projects List
                        if appState.projects.filter({ !$0.isArchived }).isEmpty {
                            Text("No projects yet")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                        } else {
                            ForEach(appState.projects.filter { !$0.isArchived }) { project in
                                projectRow(project: project)
                            }
                        }
                    }
                    
                    // User Profile Section
                    userProfileSection
                }
                .padding(.bottom, Theme.Spacing.medium)
            }
            
            // Bottom Bar
            bottomBar
        }
        .background(Theme.Colors.background)
        .frame(minWidth: 220, idealWidth: 240, maxWidth: 280)
        .sheet(isPresented: $showNewProjectSheet) {
            newProjectSheet
        }
    }
    
    // MARK: - Subviews
    
    private var appHeader: some View {
        HStack {
            Text("Seraph")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.primaryText)
            
            Spacer()
            
            // New Chat Button
            Button(action: createNewChat) {
                Image(systemName: "plus.message")
                    .font(Theme.Typography.body)
                    .padding(6)
                    .background(Theme.Colors.accent.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.top, Theme.Spacing.medium)
        .padding(.bottom, Theme.Spacing.small)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.Colors.secondaryText)
                .padding(.leading, 8)
            
            TextField("Search", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.primaryText)
                .padding(8)
                .background(Theme.Colors.background.opacity(0.5))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.bottom, Theme.Spacing.medium)
    }
    
    private var userProfileSection: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.vertical, Theme.Spacing.medium)
            
            if let user = appState.currentUser {
                HStack {
                    // User Avatar
                    if let avatarURL = user.avatarURL {
                        AsyncImage(url: avatarURL) { image in
                            image.resizable()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(Theme.Colors.primaryText)
                        
                        if let email = user.email {
                            Text(email)
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    // Settings Button
                    Button(action: { selection = .settings }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .frame(width: 32, height: 32)
                            .background(Theme.Colors.background.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.bottom, Theme.Spacing.medium)
            }
        }
    }
    
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                // App Version
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("v\(version)")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .padding(.leading, Theme.Spacing.medium)
                }
                
                Spacer()
                
                // Theme Toggle
                Button(action: {}) {
                    Image(systemName: appState.colorScheme == .dark ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                // Settings Button
                Button(action: { selection = .settings }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, Theme.Spacing.medium)
            }
            .frame(height: 44)
        }
    }
    
    private func chatRow(chat: ChatConversation) -> some View {
        let isSelected = selection?.id == "chat_\(chat.id.uuidString)"
        
        return HStack {
            Image(systemName: chat.isPinned ? "pin.fill" : "bubble.left")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Theme.Colors.accent : Theme.Colors.secondaryText)
                .frame(width: 24, height: 24)
            
            Text(chat.title)
                .font(Theme.Typography.body)
                .foregroundColor(isSelected ? Theme.Colors.accent : Theme.Colors.primaryText)
                .lineLimit(1)
            
            Spacer()
            
            if chat.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.Colors.accent)
                    .rotationEffect(.degrees(45))
                    .padding(.trailing, 4)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Theme.Colors.accent.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                selection = .chat(id: chat.id)
            }
        }
        .contextMenu {
            Button(action: { togglePin(chat: chat) }) {
                Label(
                    chat.isPinned ? "Unpin" : "Pin",
                    systemImage: chat.isPinned ? "pin.slash" : "pin"
                )
            }
            
            Button(role: .destructive, action: { deleteChat(chat) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func projectRow(project: Project) -> some View {
        let isSelected = selection?.id == "project_\(project.id.uuidString)"
        
        return HStack {
            Image(systemName: project.isArchived ? "archivebox" : "folder")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Theme.Colors.accent : Theme.Colors.secondaryText)
                .frame(width: 24, height: 24)
            
            Text(project.name)
                .font(Theme.Typography.body)
                .foregroundColor(isSelected ? Theme.Colors.accent : Theme.Colors.primaryText)
                .lineLimit(1)
            
            Spacer()
            
            if let count = project.chatCount, count > 0 {
                Text("\(count)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.Colors.background.opacity(0.5))
                    .cornerRadius(10)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Theme.Colors.accent.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                selection = .project(id: project.id)
            }
        }
        .contextMenu {
            Button(role: .destructive, action: { archiveProject(project) }) {
                Label(
                    project.isArchived ? "Unarchive" : "Archive",
                    systemImage: project.isArchived ? "tray.and.arrow.up" : "archivebox"
                )
            }
            
            Button(role: .destructive, action: { deleteProject(project) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func collapsibleSection<Content: View>(
        section: SidebarSection,
        header: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            // Section Header
            Button(action: { toggleSection(section) }) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .frame(width: 24, height: 24)
                    
                    Text(header)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    Image(systemName: expandedSections.contains(section) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .frame(width: 16, height: 16)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, Theme.Spacing.medium)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Section Content
            if expandedSections.contains(section) {
                content()
                    .padding(.leading, 8)
                    .padding(.trailing, 4)
                    .padding(.bottom, 8)
            }
        }
    }
    
    private var newProjectSheet: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Text("New Project")
                .font(Theme.Typography.title)
                .padding(.top, Theme.Spacing.medium)
            
            TextField("Project Name", text: $newProjectName)
                .textFieldStyle(.plain)
                .padding()
                .background(Theme.Colors.background.opacity(0.5))
                .cornerRadius(8)
                .padding(.horizontal, Theme.Spacing.medium)
            
            HStack(spacing: Theme.Spacing.medium) {
                Button(action: { showNewProjectSheet = false }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.background.opacity(0.5))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: createNewProject) {
                    Text("Create")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Colors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.bottom, Theme.Spacing.medium)
        }
        .frame(width: 300)
        .background(Theme.Colors.background)
    }
    
    // MARK: - Helper Methods
    
    private func toggleSection(_ section: SidebarSection) {
        withAnimation {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
    
    private func createNewChat() {
        let newChat = ChatConversation(
            id: UUID(),
            title: "New Chat",
            messages: [],
            createdAt: Date(),
            updatedAt: Date(),
            isPinned: false
        )
        appState.recentChats.insert(newChat, at: 0)
        selection = .chat(id: newChat.id)
    }
    
    private func createNewProject() {
        let name = newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        let newProject = Project(
            id: UUID(),
            name: name,
            description: "",
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false
        )
        
        appState.projects.append(newProject)
        newProjectName = ""
        showNewProjectSheet = false
        selection = .project(id: newProject.id)
    }
    
    private func deleteChat(_ chat: ChatConversation) {
        if let index = appState.recentChats.firstIndex(where: { $0.id == chat.id }) {
            appState.recentChats.remove(at: index)
        }
    }
    
    private func deleteProject(_ project: Project) {
        if let index = appState.projects.firstIndex(where: { $0.id == project.id }) {
            appState.projects.remove(at: index)
        }
    }
    
    private func archiveProject(_ project: Project) {
        if let index = appState.projects.firstIndex(where: { $0.id == project.id }) {
            appState.projects[index].isArchived.toggle()
        }
    }
    
    private func togglePin(chat: ChatConversation) {
        if let index = appState.recentChats.firstIndex(where: { $0.id == chat.id }) {
            appState.recentChats[index].isPinned.toggle()
        }
    }
}

// MARK: - Previews

#Preview {
    let appState = AppState()
    appState.currentUser = User(
        id: UUID(),
        email: "user@example.com",
        displayName: "John Doe",
        avatarURL: nil
    )
    
    // Add sample chats
    appState.recentChats = [
        ChatConversation(
            id: UUID(),
            title: "Welcome to Seraph",
            messages: [],
            createdAt: Date(),
            updatedAt: Date(),
            isPinned: true
        ),
        ChatConversation(
            id: UUID(),
            title: "Project Discussion",
            messages: [],
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date(),
            isPinned: false
        )
    ]
    
    // Add sample projects
    appState.projects = [
        Project(
            id: UUID(),
            name: "Mobile App",
            description: "New mobile application project",
            createdAt: Date(),
            updatedAt: Date(),
            isArchived: false
        ),
        Project(
            id: UUID(),
            name: "Website Redesign",
            description: "Redesign company website",
            createdAt: Date().addingTimeInterval(-86400),
            updatedAt: Date(),
            isArchived: false
        )
    ]
    
    return SidebarView(selection: .constant(.chats))
        .environmentObject(appState)
        .frame(width: 240)
        .preferredColorScheme(.dark)
}
