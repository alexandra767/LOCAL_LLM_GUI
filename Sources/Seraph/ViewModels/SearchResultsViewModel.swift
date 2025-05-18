import Foundation
import SwiftUI

@MainActor
class SearchResultsViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [SearchResult] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let searchService: SemanticSearchService
    
    init() {
        self.searchService = SemanticSearchService()
    }
    
    func search() async {
        await searchService.search(query: searchQuery)
        searchResults = searchService.searchResults
    }
    
    func openDocument(_ result: SearchResult) {
        // TODO: Implement document opening logic
        print("Opening document: \(result.title)")
    }
    
    func removeDocument(_ result: SearchResult) {
        // Remove the result from our local list
        if let index = searchResults.firstIndex(where: { $0.id == result.id }) {
            searchResults.remove(at: index)
        }
        
        // Ask the search service to remove the document
        searchService.removeDocumentById(result.id)
    }
    
    func addDocument(title: String, content: String) {
        let document = Document(
            title: title,
            content: content,
            description: "Added from search",
            tags: []
        )
        searchService.addDocument(document)
        
        // Update search results if we're currently searching
        if !searchQuery.isEmpty {
            Task {
                await search()
            }
        }
    }
}
