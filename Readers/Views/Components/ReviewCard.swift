import SwiftUI

struct ReviewCard: View {
    let review: Review
    let userName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with user info and rating
            HStack {
                VStack(alignment: .leading) {
                    Text(userName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(review.dateCreated, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Star rating
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                            .foregroundColor(star <= review.rating ? .yellow : .gray)
                            .font(.caption)
                    }
                }
            }
            
            // Review text
            if !review.reviewText.isEmpty {
                Text(review.reviewText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ReviewCard(
        review: Review(
            userId: "user1",
            bookId: "book1",
            rating: 4,
            reviewText: "This is a great book! I really enjoyed the character development and the plot twists."
        ),
        userName: "John Doe"
    )
    .padding()
} 