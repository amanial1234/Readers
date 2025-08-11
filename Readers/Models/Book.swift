import Foundation

struct Book: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let author: String
    let coverImageURL: String?
    let publishYear: Int?
    let description: String?
    let isbn: String?
    
    init(id: String, title: String, author: String, coverImageURL: String? = nil, publishYear: Int? = nil, description: String? = nil, isbn: String? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.coverImageURL = coverImageURL
        self.publishYear = publishYear
        self.description = description
        self.isbn = isbn
    }
    
    // Computed property for display
    var displayTitle: String {
        if let year = publishYear {
            return "\(title) (\(year))"
        }
        return title
    }
    
    // Computed property for formatted year
    var formattedYear: String {
        if let year = publishYear {
            return String(year)
        }
        return ""
    }
}

// Simple favorite/bookmark system
struct UserBookList: Identifiable, Codable {
    let id: String
    let userId: String
    let bookId: String
    let dateAdded: Date
    
    init(userId: String, bookId: String) {
        self.id = "\(userId)_\(bookId)"
        self.userId = userId
        self.bookId = bookId
        self.dateAdded = Date()
    }
} 