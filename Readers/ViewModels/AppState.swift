import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var firebaseService = FirebaseService()
    let bookAPIService = BookAPIService()
    
    // MARK: - Core Data
    @Published var favoriteBooks: [Book] = []
    @Published var favoritesCount: Int = 0
    
    private let favoritesKey = "favoriteBooks"
    private var cancellables = Set<AnyCancellable>()
    
    var currentUser: User? {
        firebaseService.currentUser
    }
    
    var isAuthenticated: Bool {
        firebaseService.isAuthenticated
    }
    
    // MARK: - Initialization
    init() {
        // Load favorites from local storage immediately
        loadFavoritesFromLocal()

        
        // Observe user authentication changes
        firebaseService.$currentUser.sink { [weak self] user in
            DispatchQueue.main.async {
                if let user = user {
                    print("👤 AppState: User signed in: \(user.id)")
                    // Don't overwrite local data - just sync local to Firebase
                    Task {
                        await self?.syncLocalToFirebase()
                    }
                } else {
                    print("👤 AppState: User signed out")
                    // Keep local data, just clear Firebase references
                    // Don't clear local favorites on sign out
                }
            }
        }
        .store(in: &cancellables)
        
        // Observe authentication changes for UI updates
        firebaseService.$isAuthenticated.sink { [weak self] isAuthenticated in
            DispatchQueue.main.async {
                print("🔐 AppState: isAuthenticated changed to: \(isAuthenticated)")
                self?.objectWillChange.send()
            }
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Core Favorites Management
    
    func addBookToFavorites(_ book: Book) {
        // Check if already in favorites
        if favoriteBooks.contains(where: { $0.id == book.id }) {
            return
        }
        
        // 1. Add to local array (instant UI update)
        favoriteBooks.append(book)
        favoritesCount = favoriteBooks.count
        
        // 2. Save to local storage (persistence)
        saveFavoritesToLocal()
        
        // 3. Optional: Sync to Firebase (background, doesn't affect local)
        if isAuthenticated {
            Task {
                await syncBookToFirebase(book)
            }
        }
    }
    
    func removeBookFromFavorites(bookId: String) {
        // 1. Remove from local array (instant UI update)
        favoriteBooks.removeAll { $0.id == bookId }
        favoritesCount = favoriteBooks.count
        
        // 2. Save to local storage (persistence)
        saveFavoritesToLocal()
        
        // 3. Optional: Remove from Firebase (background, doesn't affect local)
        if isAuthenticated {
            Task {
                await removeBookFromFirebase(bookId: bookId)
            }
        }
    }
    
    func isBookInFavorites(bookId: String) -> Bool {
        return favoriteBooks.contains { $0.id == bookId }
    }
    
    // MARK: - Local Storage (Single Source of Truth)
    
    private func saveFavoritesToLocal() {
        if let encoded = try? JSONEncoder().encode(favoriteBooks) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func loadFavoritesFromLocal() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey) {
            if let books = try? JSONDecoder().decode([Book].self, from: data) {
                self.favoriteBooks = books
                self.favoritesCount = books.count
            }
        }
    }
    
    // MARK: - Firebase Sync (Optional Backup)
    
    private func syncBookToFirebase(_ book: Book) async {
        guard let userId = currentUser?.id else { return }
        
        do {
            try await firebaseService.addBookToFavorites(userId: userId, bookId: book.id)
        } catch {
            print("❌ Failed to sync '\(book.title)' to Firebase: \(error)")
            // Don't affect local data - Firebase failure is not critical
        }
    }
    
    private func removeBookFromFirebase(bookId: String) async {
        guard let userId = currentUser?.id else { return }
        
        do {
            try await firebaseService.removeBookFromFavorites(userId: userId, bookId: bookId)
        } catch {
            print("❌ Failed to remove book \(bookId) from Firebase: \(error)")
            // Don't affect local data - Firebase failure is not critical
        }
    }
    
    func syncLocalToFirebase() async {
        guard let userId = currentUser?.id else { return }
        
        for book in favoriteBooks {
            do {
                try await firebaseService.addBookToFavorites(userId: userId, bookId: book.id)
            } catch {
                print("❌ Failed to sync '\(book.title)' to Firebase: \(error)")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func refreshFavorites() {
        // Just reload from local storage
        loadFavoritesFromLocal()
    }
    
    func forceRefreshFavorites() {
        loadFavoritesFromLocal()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, displayName: String) async throws {
        try await firebaseService.signUp(email: email, password: password, displayName: displayName)
    }
    
    func signIn(email: String, password: String) async throws {
        try await firebaseService.signIn(email: email, password: password)
    }
    
    func signOut() throws {
        try firebaseService.signOut()
        // Keep local favorites - don't clear them on sign out
    }
    
    // MARK: - User Profile Methods
    
    func updateProfile(displayName: String, bio: String?, profileImageURL: String? = nil) async throws {
        guard var user = currentUser else { return }
        user.displayName = displayName
        user.bio = bio
        if let profileImageURL = profileImageURL {
            user.profileImageURL = profileImageURL
        }
        try await firebaseService.updateUserProfile(user)
    }
    

}

