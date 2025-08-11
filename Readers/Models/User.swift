import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    let id: String
    var displayName: String
    var email: String
    var bio: String?
    var profileImageURL: String?
    var dateJoined: Date
    
    init(id: String, displayName: String, email: String, bio: String? = nil, profileImageURL: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.dateJoined = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case email
        case bio
        case profileImageURL
        case dateJoined
    }
} 