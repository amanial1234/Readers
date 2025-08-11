import Foundation
import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isWaitingForInput = false
    
    private let bookAPIService: BookAPIService
    private let firebaseService: FirebaseService
    private var searchCancellable: AnyCancellable?
    
    init(bookAPIService: BookAPIService, firebaseService: FirebaseService) {
        self.bookAPIService = bookAPIService
        self.firebaseService = firebaseService
        
        // Set up debounced search
        setupDebouncedSearch()
    }
    
    // MARK: - Debounced Search Setup
    
    private func setupDebouncedSearch() {
        searchCancellable = $searchText
            .handleEvents(receiveSubscription: { _ in
                // This will be called when the search text changes
            }, receiveOutput: { [weak self] _ in
                // Show waiting state when user types
                Task { @MainActor in
                    self?.isWaitingForInput = true
                }
            })
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                Task {
                    await self?.performSearch(searchTerm: searchTerm)
                }
            }
    }
    
    // MARK: - Search Methods
    
    private func performSearch(searchTerm: String) async {
        // Clear waiting state
        await MainActor.run {
            isWaitingForInput = false
        }
        
        // Don't search if the term is empty or just whitespace
        let trimmedTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else {
            // Clear results if search term is empty
            await MainActor.run {
                searchResults = []
                errorMessage = nil
            }
            return
        }
        
        // Don't search if the term is too short (optional)
        guard trimmedTerm.count >= 2 else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let results = try await bookAPIService.searchBooks(query: trimmedTerm)
            await MainActor.run {
                searchResults = results
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    // Manual search method (for button press if needed)
    func searchBooks() async {
        await performSearch(searchTerm: searchText)
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        errorMessage = nil
    }
    
    func isBookInFavorites(bookId: String) -> Bool {
        // Check if the current user has this book in favorites
        guard let userId = firebaseService.currentUser?.id else { return false }
        
        // For now, return false. In a real app, you'd want to cache this or check more efficiently
        return false
    }
} 