
# Readers - A Letterboxd for Books

A SwiftUI iOS app that helps users discover, track, and review books. Built with modern iOS development practices and Firebase backend services.

## Features

### 🔐 Authentication
- Email/password sign up and sign in
- User profile management
- Secure Firebase Authentication

### 📚 Book Discovery
- Search books using Open Library API
- Browse book covers, titles, authors, and descriptions
- Add books to personal reading lists

### 📖 Reading Lists
- **Want to Read**: Books you plan to read
- **Reading**: Books currently in progress
- **Read**: Completed books
- Easy list management with swipe actions

### ⭐ Reviews & Ratings
- Rate books from 1-5 stars
- Write detailed reviews
- View reviews from other users
- Community-driven book recommendations

### 👤 User Profiles
- Customizable display names and bios
- Reading statistics and progress tracking
- Public profile sharing

## Tech Stack

- **iOS 17+** with **Swift 5.9**
- **SwiftUI** for modern, declarative UI
- **Firebase** for backend services:
  - Authentication
  - Firestore Database
  - Cloud Storage (for profile images)
- **Open Library API** for book data
- **MVVM Architecture** with ObservableObject pattern

## Project Structure

```
Readers/
├── Models/           # Data models
│   ├── User.swift
│   ├── Book.swift
│   ├── Review.swift
│   └── MockData.swift
├── Views/            # SwiftUI views
│   ├── Components/   # Reusable UI components
│   ├── Authentication/
│   ├── Search/
│   ├── Books/
│   └── Profile/
├── ViewModels/       # Business logic and state
│   ├── AppState.swift
│   ├── SearchViewModel.swift
│   └── MyBooksViewModel.swift
├── Services/         # API and Firebase services
│   ├── FirebaseService.swift
│   └── BookAPIService.swift
└── MainTabView.swift # Main tab navigation
```

## Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ deployment target
- Firebase project setup

### 1. Firebase Setup
1. Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Authentication with Email/Password provider
3. Create a Firestore Database in test mode
4. Download `GoogleService-Info.plist` and add to your Xcode project

### 2. Firebase Dependencies
Add the following to your Xcode project using Swift Package Manager:
```
https://github.com/firebase/firebase-ios-sdk
```

Select these packages:
- FirebaseAuth
- FirebaseFirestore
- FirebaseFirestoreSwift

### 3. Open Library API
The app uses the free Open Library API for book data. No API key required.

### 4. Build and Run
1. Open `Readers.xcodeproj` in Xcode
2. Select your development team
3. Build and run on iOS simulator or device

## Architecture

### MVVM Pattern
- **Models**: Pure data structures conforming to `Codable`
- **Views**: SwiftUI views with minimal business logic
- **ViewModels**: ObservableObject classes managing state and business logic
- **Services**: Network and database operations

### State Management
- `AppState`: Central app state and authentication
- `FirebaseService`: Firebase operations and user management
- `BookAPIService`: Open Library API integration
- Individual ViewModels for specific features

### Data Flow
1. User interactions trigger ViewModel methods
2. ViewModels call appropriate services
3. Services update the app state
4. UI automatically updates via SwiftUI's reactive system

## Firebase Collections

### Users
```json
{
  "id": "user123",
  "displayName": "John Doe",
  "email": "john@example.com",
  "bio": "Avid reader...",
  "profileImageURL": "https://...",
  "dateJoined": "2024-01-01T00:00:00Z"
}
```

### UserBookLists
```json
{
  "id": "user123_book456",
  "userId": "user123",
  "bookId": "book456",
  "listType": "Want to Read",
  "dateAdded": "2024-01-01T00:00:00Z"
}
```

### Reviews
```json
{
  "id": "user123_book456",
  "userId": "user123",
  "bookId": "book456",
  "rating": 5,
  "reviewText": "Amazing book!",
  "dateCreated": "2024-01-01T00:00:00Z"
}
```

## Future Enhancements

- [ ] Social features: follow users, see friends' reading activity
- [ ] Book recommendations based on reading history
- [ ] Reading challenges and goals
- [ ] Book clubs and group discussions
- [ ] Push notifications for reading reminders
- [ ] Offline reading list support
- [ ] Book scanning with camera
- [ ] Integration with Goodreads/other platforms

## Contributing

This is an MVP project. Feel free to fork and enhance with additional features!

## License

MIT License - see LICENSE file for details 
>>>>>>> 9d83418 (Intial Code)
