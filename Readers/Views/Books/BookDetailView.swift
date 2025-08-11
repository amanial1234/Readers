import SwiftUI

struct BookDetailView: View {
    let book: Book
    @EnvironmentObject var appState: AppState
    @State private var reviews: [Review] = []
    @State private var isLoadingReviews = false
    @State private var showingReviewSheet = false
    @State private var userRating = 3
    @State private var userReviewText = ""
    @State private var isSubmittingReview = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Book header
                HStack(spacing: 20) {
                    // Cover image
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
                                    .font(.largeTitle)
                            )
                    }
                    .frame(width: 120, height: 160)
                    .cornerRadius(12)
                    
                    // Book info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(3)
                        
                        Text("by \(book.author)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let year = book.publishYear {
                            Text("Published \(book.formattedYear)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let isbn = book.isbn {
                            Text("ISBN: \(isbn)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Bookmark button
                        if appState.isAuthenticated {
                            Button(action: {
                                if appState.isBookInFavorites(bookId: book.id) {
                                    // Book is already favorite, remove it
                                    Task {
                                        await appState.removeBookFromFavorites(bookId: book.id)
                                    }
                                } else {
                                    // Book is not favorite, add it
                                    Task {
                                        await appState.addBookToFavorites(book)
                                    }
                                }
                            }) {
                                Image(systemName: appState.isBookInFavorites(bookId: book.id) ? "bookmark.fill" : "bookmark")
                                    .foregroundColor(appState.isBookInFavorites(bookId: book.id) ? .blue : .gray)
                                    .font(.title)
                            }
                            .padding(.top, 8)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Description
                if let description = book.description {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(description)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                }
                
                // Reviews section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Reviews")
                            .font(.headline)
                        
                        Spacer()
                        
                        if appState.isAuthenticated {
                            Button("Write Review") {
                                showingReviewSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.horizontal)
                    
                    if isLoadingReviews {
                        ProgressView("Loading reviews...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if reviews.isEmpty {
                        Text("No reviews yet. Be the first to review this book!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(reviews) { review in
                                ReviewCard(
                                    review: review,
                                    userName: "User" // In a real app, fetch user names
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadReviews()
        }
        .sheet(isPresented: $showingReviewSheet) {
            ReviewSheet(
                book: book,
                rating: $userRating,
                reviewText: $userReviewText,
                isSubmitting: $isSubmittingReview,
                onSubmit: submitReview
            )
        }
    }
    
    private func loadReviews() {
        isLoadingReviews = true
        
        Task {
            do {
                reviews = try await appState.firebaseService.getBookReviews(bookId: book.id)
            } catch {
                print("Error loading reviews: \(error)")
            }
            
            isLoadingReviews = false
        }
    }
    

    
    private func submitReview() {
        guard let userId = appState.currentUser?.id else { return }
        
        isSubmittingReview = true
        
        let review = Review(
            userId: userId,
            bookId: book.id,
            rating: userRating,
            reviewText: userReviewText
        )
        
        Task {
            do {
                try await appState.firebaseService.saveReview(review)
                await loadReviews()
                showingReviewSheet = false
                userReviewText = ""
                userRating = 3
            } catch {
                print("Error submitting review: \(error)")
            }
            
            isSubmittingReview = false
        }
    }
}

struct ReviewSheet: View {
    let book: Book
    @Binding var rating: Int
    @Binding var reviewText: String
    @Binding var isSubmitting: Bool
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Review: \(book.title)")
                    .font(.headline)
                
                // Rating
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rating")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { rating = star }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                                    .font(.title2)
                            }
                        }
                    }
                }
                
                // Review text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextEditor(text: $reviewText)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        onSubmit()
                    }
                    .disabled(reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        BookDetailView(
            book: Book(
                id: "1",
                title: "The Great Gatsby",
                author: "F. Scott Fitzgerald",
                coverImageURL: nil,
                publishYear: 1925,
                description: "A story of the fabulously wealthy Jay Gatsby and his love for the beautiful Daisy Buchanan."
            )
        )
    }
} 