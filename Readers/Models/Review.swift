import Foundation

struct Review: Identifiable, Codable {
    let id: String
    let userId: String
    let bookId: String
    let rating: Int
    let reviewText: String
    let dateCreated: Date
    
    init(userId: String, bookId: String, rating: Int, reviewText: String) {
        self.id = "\(userId)_\(bookId)"
        self.userId = userId
        self.bookId = bookId
        self.rating = max(1, min(5, rating)) // Ensure rating is between 1-5
        self.reviewText = reviewText
        self.dateCreated = Date()
    }
    
    // Validation
    var isValidRating: Bool {
        return rating >= 1 && rating <= 5
    }
    
    var isValidReview: Bool {
        return !reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
} 