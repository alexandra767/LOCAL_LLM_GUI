import SwiftUI

struct SearchResultsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = SearchResultsViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                VStack {
                    HStack {
                        TextField("Search documents...", text: $viewModel.searchQuery, onCommit: {
                            Task {
                                await viewModel.search()
                            }
                        })
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        
                        Button(action: {
                            viewModel.searchQuery = ""
                            viewModel.searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .opacity(viewModel.searchQuery.isEmpty ? 0 : 1)
                    }
                    .padding(.horizontal)
                    
                    if !viewModel.searchQuery.isEmpty {
                        Text("\(viewModel.searchResults.count) results found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .padding()
                
                // Results List
                List {
                    ForEach(viewModel.searchResults) { result in
                        SearchResultRowView(result: result)
                            .onTapGesture {
                                // Open document
                                viewModel.openDocument(result)
                            }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            viewModel.removeDocument(viewModel.searchResults[index])
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .background(Color(NSColor(red: 0.1176, green: 0.1176, blue: 0.1176, alpha: 1.0)))
            .navigationTitle("Search")
            .refreshable {
                await viewModel.search()
            }
        }
    }
}

struct SearchResultRowView: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(String(format: "%.1f", result.similarity * 100))% match")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(result.snippet)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(3)
        }
    }
}

#Preview {
    SearchResultsView()
        .environmentObject(AppState())
}
