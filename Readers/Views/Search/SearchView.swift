import SwiftUI

struct SearchView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: SearchViewModel
    
    init(appState: AppState) {
        self.appState = appState
        self._viewModel = StateObject(wrappedValue: SearchViewModel(
            bookAPIService: appState.bookAPIService,
            firebaseService: appState.firebaseService
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar with improved UX
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Start typing to search books...", text: $viewModel.searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        // Clear button when there's text
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Search status and results
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Searching...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.isWaitingForInput && !viewModel.searchText.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Waiting for you to finish typing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Search Error")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No books found")
                            .font(.headline)
                        Text("Try a different search term")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        Text("Search for books")
                            .font(.headline)
                        Text("Start typing to find your next great read")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Search results
                    List(viewModel.searchResults) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            BookRow(
                                book: book,
                                onToggleFavorite: {
                                    Task {
                                        if appState.isBookInFavorites(bookId: book.id) {
                                            // Book is already favorite, remove it
                                            await appState.removeBookFromFavorites(bookId: book.id)
                                        } else {
                                            // Book is not favorite, add it
                                            await appState.addBookToFavorites(book)
                                        }
                                    }
                                },
                                isFavorite: appState.isBookInFavorites(bookId: book.id)
                            )
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .toolbar {
                if !viewModel.searchResults.isEmpty {
                    Button("Clear") {
                        viewModel.clearSearch()
                    }
                }
            }
        }
        .environmentObject(appState)
    }
}

