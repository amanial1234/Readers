import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var favoritesCount = 0
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                // Use Task to handle async call
                Task {
                    await self?.fetchUserData(userId: user.uid)
                }
            } else {
                DispatchQueue.main.async {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, displayName: String) async throws {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = User(id: result.user.uid, displayName: displayName, email: email)
            try await saveUserToFirestore(user)
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            // After successful sign in, fetch user data to update the state
            await fetchUserData(userId: result.user.uid)
        } catch {
            throw error
        }
    }
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - User Management
    
    private func saveUserToFirestore(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user)
    }
    
    private func fetchUserData(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            if let user = try? document.data(as: User.self) {
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                }
            }
        } catch {
            print("🔥 Error fetching user data: \(error)")
        }
    }
    
    func updateUserProfile(_ user: User) async throws {
        try await saveUserToFirestore(user)
        self.currentUser = user
    }
    
    // MARK: - Book Lists (Favorites)
    
    func addBookToFavorites(userId: String, bookId: String) async throws {
        let userBookList = UserBookList(userId: userId, bookId: bookId)
        
        do {
            try await db.collection("userBookLists").document(userBookList.id).setData(from: userBookList)
            
            // Update the count
            await MainActor.run {
                self.favoritesCount += 1
            }
        } catch {
            print("❌ FirebaseService: Error adding book to Firestore: \(error)")
            throw error
        }
    }
    
    func removeBookFromFavorites(userId: String, bookId: String) async throws {
        try await db.collection("userBookLists").document("\(userId)_\(bookId)").delete()
        
        // Update the count
        await MainActor.run {
            self.favoritesCount = max(0, self.favoritesCount - 1)
        }
    }
    
    func getUserFavorites(userId: String) async throws -> [UserBookList] {
        let snapshot = try await db.collection("userBookLists")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let favorites = try snapshot.documents.compactMap { document in
            try document.data(as: UserBookList.self)
        }
        
        // Update the count
        await MainActor.run {
            self.favoritesCount = favorites.count
        }
        
        return favorites
    }
    
    func isBookInFavorites(userId: String, bookId: String) async throws -> Bool {
        let document = try await db.collection("userBookLists").document("\(userId)_\(bookId)").getDocument()
        return document.exists
    }
    
    // MARK: - Reviews
    
    func saveReview(_ review: Review) async throws {
        try db.collection("reviews").document(review.id).setData(from: review)
    }
    
    func getBookReviews(bookId: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("bookId", isEqualTo: bookId)
            .order(by: "dateCreated", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Review.self)
        }
    }
    
    func getUserReviews(userId: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("userId", isEqualTo: userId)
            .order(by: "dateCreated", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Review.self)
        }
    }
} 
