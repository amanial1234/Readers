import SwiftUI

struct BookRow: View {
    let book: Book
    let onToggleFavorite: (() -> Void)?
    let isFavorite: Bool
    
    init(book: Book, onToggleFavorite: (() -> Void)? = nil, isFavorite: Bool = false) {
        self.book = book
        self.onToggleFavorite = onToggleFavorite
        self.isFavorite = isFavorite
        print("🔖 BookRow: \(book.title) - isFavorite: \(isFavorite)")
    }
    
    var body: some View {
        HStack(spacing: 12) {
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
                        .onAppear {
                            print("🔖 BookRow: Displaying year '\(year)' (formatted: '\(book.formattedYear)') for book '\(book.title)'")
                        }
                }
            }
            
            Spacer()
            
            // Action buttons
            if let onToggleFavorite = onToggleFavorite {
                Button(action: {
                    print("🔖 BookRow: Tapping bookmark for \(book.title) (currently \(isFavorite ? "favorite" : "not favorite"))")
                    onToggleFavorite()
                }) {
                    Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isFavorite ? .blue : .gray)
                        .font(.title2)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    BookRow(
        book: Book(
            id: "1",
            title: "The Great Gatsby",
            author: "F. Scott Fitzgerald",
            coverImageURL: nil,
            publishYear: 1925
        ),
        onToggleFavorite: {},
        isFavorite: false
    )
    .padding()
} 