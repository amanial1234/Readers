import Foundation

class BookAPIService: ObservableObject {
    private let baseURL = "https://openlibrary.org"
    
    // MARK: - Search Books
    
    func searchBooks(query: String) async throws -> [Book] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search.json?q=\(encodedQuery)&limit=20") else {
            throw BookAPIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BookAPIError.invalidResponse
        }
        
        let searchResponse = try JSONDecoder().decode(OpenLibrarySearchResponse.self, from: data)
        
        return searchResponse.docs.map { doc in
            
            // Try to get author from different possible fields
            let author = doc.authorName?.first ?? 
                        doc.authorName?.joined(separator: ", ") ?? 
                        "Unknown Author"
            
            // Generate cover URL with fallback sizes
            let coverURL: String?
            if let coverId = doc.coverI {
                coverURL = "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg"
            } else {
                coverURL = nil
            }
            
            let book = Book(
                id: doc.key,
                title: doc.title,
                author: author,
                coverImageURL: coverURL,
                publishYear: doc.firstPublishYear,
                description: doc.description?.first,
                isbn: doc.isbn?.first
            )
            
            return book
        }
    }
    
    // MARK: - Get Book Details
    
    func getBookDetails(bookId: String) async throws -> Book {
        guard let url = URL(string: "\(baseURL)/works/\(bookId).json") else {
            throw BookAPIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BookAPIError.invalidResponse
        }
        
        let bookResponse = try JSONDecoder().decode(OpenLibraryBookResponse.self, from: data)
        
        let parsedYear = bookResponse.firstPublishDate.flatMap { dateString in
            let cleanedString = dateString.replacingOccurrences(of: ",", with: "")
            let yearString = String(cleanedString.prefix(4))
            let year = Int(yearString)
            return year
        }
        
        let book = Book(
            id: bookId,
            title: bookResponse.title,
            author: bookResponse.authors?.first?.name ?? "Unknown Author",
            coverImageURL: bookResponse.covers?.first != nil ? "https://covers.openlibrary.org/b/id/\(bookResponse.covers!.first!)-L.jpg" : nil,
            publishYear: parsedYear,
            description: bookResponse.description?.value,
            isbn: nil
        )
        
        return book
    }
}

// MARK: - Open Library API Response Models

struct OpenLibrarySearchResponse: Codable {
    let docs: [OpenLibraryDoc]
}

struct OpenLibraryDoc: Codable {
    let key: String
    let title: String
    let authorName: [String]?
    let coverI: Int?
    let firstPublishYear: Int?
    let description: [String]?
    let isbn: [String]?
    
    // Custom coding keys to match the actual API response
    enum CodingKeys: String, CodingKey {
        case key
        case title
        case authorName = "author_name"
        case coverI = "cover_i"
        case firstPublishYear = "first_publish_year"
        case description
        case isbn
    }
}

struct OpenLibraryBookResponse: Codable {
    let title: String
    let authors: [OpenLibraryAuthor]?
    let covers: [Int]?
    let firstPublishDate: String?
    let description: OpenLibraryDescription?
}

struct OpenLibraryAuthor: Codable {
    let name: String
}

struct OpenLibraryDescription: Codable {
    let value: String
}

// MARK: - Errors

enum BookAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        }
    }
} 
