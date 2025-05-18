import SwiftUI

struct NewProjectView: View {
    let viewModel: ProjectViewModel
    
    @State private var name: String = ""
    @State private var description: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.15, green: 0.15, blue: 0.15).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Create New Project")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Name")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter project name", text: $name)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $description)
                                .padding(4)
                                .frame(height: 120)
                                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            
                            if description.isEmpty {
                                Text("Enter project description")
                                    .foregroundColor(.gray)
                                    .allowsHitTesting(false)
                                    .padding(.top, 8)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.18, green: 0.18, blue: 0.18))
                        .cornerRadius(8)
                        
                        Button("Create Project") {
                            viewModel.createProject(name: name, description: description)
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            name.isEmpty ? 
                            Color.gray.opacity(0.5) : 
                            Color(red: 0.3, green: 0.5, blue: 0.8)
                        )
                        .cornerRadius(8)
                        .disabled(name.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                EmptyView()
            }
        }
    }
}

// This extension is no longer needed as we're using the built-in placeholder
