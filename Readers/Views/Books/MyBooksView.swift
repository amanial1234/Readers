import SwiftUI

struct MyBooksView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack {
                if !appState.isAuthenticated {
                    // Not authenticated state
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Sign in to view your favorites")
                            .font(.headline)
                        
                        Text("Save books you love to your favorites")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Authenticated state - show favorites
                    FavoritesListView(appState: appState)
                }
            }
            .navigationTitle("My Favorites")
            .toolbar {
                if appState.isAuthenticated {
                    Button(action: {
                        appState.forceRefreshFavorites()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                if appState.isAuthenticated {
                    Task {
                        await appState.refreshFavorites()
                    }
                }
            }
        }
    }
}

struct FavoritesListView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack {
            if appState.favoriteBooks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("No favorite books yet")
                            .font(.headline)
                        
                        Text("Start adding books to your favorites while browsing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(appState.favoriteBooks, id: \.id) { book in
                        HStack {
                            // Book cover
                            AsyncImage(url: URL(string: book.coverImageURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "book")
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(width: 60, height: 80)
                            .cornerRadius(8)
                            
                            // Book info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                
                                Text(book.author)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                if let year = book.publishYear {
                                    Text(book.formattedYear)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    await appState.removeBookFromFavorites(bookId: book.id)
                                }
                            }) {
                                Image(systemName: "bookmark.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                        }
                    }
                    .refreshable {
                        await appState.refreshFavorites()
                    }
                    .onAppear {
                        // Force refresh from local storage when view appears
                        appState.forceRefreshFavorites()
                    }
                }
        }
    }
}

#Preview {
    MyBooksView()
} 
