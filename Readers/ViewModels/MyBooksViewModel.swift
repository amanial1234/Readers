import Foundation
import SwiftUI

@MainActor
class MyBooksViewModel: ObservableObject {
    @Published var userFavorites: [UserBookList] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService: FirebaseService
    private let bookAPIService: BookAPIService
    
    init(firebaseService: FirebaseService, bookAPIService: BookAPIService) {
        self.firebaseService = firebaseService
        self.bookAPIService = bookAPIService
    }
    
    func loadUserFavorites() async {
        guard let userId = firebaseService.currentUser?.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            userFavorites = try await firebaseService.getUserFavorites(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addBookToFavorites(bookId: String) async {
        guard let userId = firebaseService.currentUser?.id else { return }
        
        do {
            try await firebaseService.addBookToFavorites(userId: userId, bookId: bookId)
            await loadUserFavorites()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeBookFromFavorites(bookId: String) async {
        guard let userId = firebaseService.currentUser?.id else { return }
        
        do {
            try await firebaseService.removeBookFromFavorites(userId: userId, bookId: bookId)
            await loadUserFavorites()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func getFavoriteCount() -> Int {
        return userFavorites.count
    }
} 