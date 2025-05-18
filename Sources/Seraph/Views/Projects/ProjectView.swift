import SwiftUI

struct ProjectView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ProjectViewModel()
    @State private var searchText = ""
    @State private var sortOption = "Activity"
    
    var sortedProjects: [Project] {
        let filteredProjects = searchText.isEmpty ? viewModel.projects : viewModel.projects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
        
        switch sortOption {
        case "Name":
            return filteredProjects.sorted { $0.name < $1.name }
        case "Created":
            return filteredProjects.sorted { $0.createdAt > $1.createdAt }
        case "Updated":
            return filteredProjects.sorted { $0.updatedAt > $1.updatedAt }
        default: // "Activity"
            return filteredProjects.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title centered
            Text("Projects")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
            
            // Search and New Project
            HStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search projects...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                .cornerRadius(8)
                
                Spacer()
                
                // Sort menu
                Menu {
                    Button("Activity", action: { sortOption = "Activity" })
                    Button("Name", action: { sortOption = "Name" })
                    Button("Created", action: { sortOption = "Created" })
                    Button("Updated", action: { sortOption = "Updated" })
                } label: {
                    HStack {
                        Text("Sort by")
                            .foregroundColor(.gray)
                        Text(sortOption)
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // New Project Button - Top right
            HStack {
                Spacer()
                Button(action: {
                    viewModel.showNewProjectSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("New project")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Context Input Area - Claude-like larger input area
            VStack(alignment: .leading) {
                Text("Model Context")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 10) {
                    // Text area for direct input
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $viewModel.contextText)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .frame(minHeight: 120, maxHeight: .infinity)
                            .background(Color(red: 0.18, green: 0.18, blue: 0.18))
                            .cornerRadius(12)
                            .padding(1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            
                        if viewModel.contextText.isEmpty {
                            Text("Enter your questions or add context here...")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding([.top, .leading], 8)
                        }
                    }
                    
                    // Button Row
                    HStack {
                        // Add Files button with enhanced icon
                        Button(action: {
                            viewModel.showFileImporter = true
                        }) {
                            HStack {
                                Image(systemName: "doc.fill.badge.plus")
                                    .foregroundColor(.white)
                                    .font(.system(size: 13))
                                Text("Add Files")
                                    .foregroundColor(.white)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.25, green: 0.25, blue: 0.25))
                            .cornerRadius(20)
                        }
                        
                        // Add Folder button with enhanced icon
                        Button(action: {
                            viewModel.showFolderImporter = true
                        }) {
                            HStack {
                                Image(systemName: "folder.fill.badge.plus")
                                    .foregroundColor(.white)
                                    .font(.system(size: 13))
                                Text("Add Folder")
                                    .foregroundColor(.white)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.25, green: 0.25, blue: 0.25))
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        // Submit Button
                        Button(action: {
                            // Submit action
                            viewModel.submitToModel()
                        }) {
                            HStack {
                                Text("Send")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .semibold))
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.3, green: 0.5, blue: 0.8))
                            .cornerRadius(20)
                        }
                        .disabled(viewModel.contextText.isEmpty)
                        .opacity(viewModel.contextText.isEmpty ? 0.5 : 1.0)
                    }
                }
            }
            .padding()
            .background(Color(red: 0.16, green: 0.16, blue: 0.16))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 20)
            .frame(minHeight: 200)
            
            // Model Response Area
            if !viewModel.modelResponse.isEmpty || viewModel.isLoading {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Response")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Generating response...")
                                .foregroundColor(.gray)
                                .padding(.leading, 8)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.18, green: 0.18, blue: 0.18))
                        .cornerRadius(12)
                    } else {
                        Text(viewModel.modelResponse)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.18, green: 0.18, blue: 0.18))
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(red: 0.16, green: 0.16, blue: 0.16))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            
            // Project Cards Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: 350), spacing: 16)], spacing: 16) {
                    ForEach(viewModel.showingAllProjects ? sortedProjects : sortedProjects.prefix(4).map{$0}) { project in
                        ProjectCardView(project: project, viewModel: viewModel)
                    }
                }
                .padding()
            }
            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
            
            // View All button
            Button(action: {
                viewModel.showingAllProjects.toggle()
            }) {
                Text(viewModel.showingAllProjects ? "Show less" : "View all")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.18, green: 0.18, blue: 0.18))
                    .cornerRadius(8)
            }
            .padding()
        }
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .sheet(isPresented: $viewModel.showNewProjectSheet) {
            NewProjectView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showProjectDetail) {
            if let selectedProject = viewModel.selectedProject {
                ProjectDetailView(project: selectedProject)
                    .environmentObject(viewModel)
            }
        }
        .fileImporter(
            isPresented: $viewModel.showFileImporter,
            allowedContentTypes: [.text, .plainText, .json, .xml, .propertyList, .sourceCode, .pdf, .rtf, .png, .jpeg, .data],
            allowsMultipleSelection: true
        ) { result in
            do {
                let urls = try result.get()
                viewModel.addFilesToContext(urls)
            } catch {
                print("Error importing files: \(error)")
            }
        }
        .fileImporter(
            isPresented: $viewModel.showFolderImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            do {
                let urls = try result.get()
                if let url = urls.first {
                    viewModel.addFolderToContext(url)
                }
            } catch {
                print("Error importing folder: \(error)")
            }
        }
    }
}

struct ProjectCardView: View {
    let project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @State private var showDeleteConfirmation = false
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            // Navigate to project detail view
            viewModel.selectedProject = project
            viewModel.showProjectDetail = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Project Title
                Text(project.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Description
                Text(project.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .padding(.bottom, 4)
                
                // Footer with updated time
                HStack {
                    Text("Updated \(formattedUpdatedTime)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Only show delete button on hover (similar to Claude3.png design)
                    if isHovering {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red.opacity(0.8))
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.opacity)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.18, green: 0.18, blue: 0.18))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Delete Project", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteProject(project)
            }
        } message: {
            Text("Are you sure you want to delete '\(project.name)'? This action cannot be undone.")
        }
    }
    
    // Format the time like in Claude3.png: "X days ago"
    var formattedUpdatedTime: String {
        let calendar = Calendar.current
        let now = Date()
        
        if let days = calendar.dateComponents([.day], from: project.updatedAt, to: now).day {
            if days == 0 {
                return "today"
            } else if days == 1 {
                return "1 day ago"
            } else {
                return "\(days) days ago"
            }
        }
        
        return project.updatedAt.formatted(date: .abbreviated, time: .omitted)
    }
}

#Preview {
    ProjectView()
        .environmentObject(AppState())
}
