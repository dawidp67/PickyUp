# Pickup Game Organizer - iOS App Implementation Plan

## Project Overview
An iOS app for organizing pickup soccer and basketball games among a close group of friends (5-50 people). Users can discover games on a map, create new games, and RSVP to attend.

**Tech Stack:**
- SwiftUI for UI
- Firebase Authentication for user management
- Firebase Firestore for database
- Firebase Cloud Messaging for push notifications
- MapKit (native) or Mapbox for map visualization

---

## Core Features

### Phase 1: MVP (Minimum Viable Product)
1. **User Authentication**
   - Email/password signup and login
   - Basic profile creation (name, profile photo)
   - Password reset functionality

2. **Game Creation**
   - Create game with:
     - Sport type (Soccer or Basketball)
     - Location (address with map pin)
     - Date and time
     - Duration
     - Optional description/notes
   - Edit/delete own games

3. **Game Discovery**
   - Map view showing all upcoming games
   - Custom pins/icons for soccer vs basketball
   - Tap pin to view game details
   - List view as alternative to map

4. **RSVP System**
   - "Going" or "Maybe" attendance options
   - View list of attendees
   - See total count of confirmed players

5. **User Profile**
   - View/edit own profile
   - Display name and photo
   - List of games user created or attending

### Phase 2: Enhanced Features
1. **Push Notifications**
   - New game created in area
   - Game updates or cancellations
   - Reminder 2 hours before game time
   - Someone RSVPs to your game

2. **Filtering & Search**
   - Filter by sport type
   - Filter by date range
   - Filter by distance from user

3. **Game Management**
   - Cancellation with notification to attendees
   - Game status (Active, Cancelled, Completed)
   - Mark games as completed

### Phase 3: Future Enhancements
1. In-app messaging/comments on games
2. User reputation/rating system
3. Recurring games
4. Weather integration
5. Add more sports
6. Friend system
7. Private vs public games

---

## Technical Architecture

### Data Models

#### User
```swift
struct User: Codable, Identifiable {
    var id: String // Firebase Auth UID
    var email: String
    var displayName: String
    var profilePhotoURL: String?
    var createdAt: Date
    var fcmToken: String? // For push notifications
}
```

#### Game
```swift
struct Game: Codable, Identifiable {
    var id: String
    var creatorId: String
    var sportType: SportType // enum: soccer, basketball
    var location: GameLocation
    var dateTime: Date
    var duration: Int // in minutes
    var description: String?
    var status: GameStatus // enum: active, cancelled, completed
    var createdAt: Date
    var updatedAt: Date
}

struct GameLocation: Codable {
    var address: String
    var latitude: Double
    var longitude: Double
    var placeName: String?
}

enum SportType: String, Codable, CaseIterable {
    case soccer
    case basketball
}

enum GameStatus: String, Codable {
    case active
    case cancelled
    case completed
}
```

#### RSVP
```swift
struct RSVP: Codable, Identifiable {
    var id: String
    var gameId: String
    var userId: String
    var status: RSVPStatus // enum: going, maybe
    var createdAt: Date
    var updatedAt: Date
}

enum RSVPStatus: String, Codable {
    case going
    case maybe
}
```

### Firebase Structure

```
users/
  {userId}/
    - email
    - displayName
    - profilePhotoURL
    - createdAt
    - fcmToken

games/
  {gameId}/
    - creatorId
    - sportType
    - location (map)
    - dateTime
    - duration
    - description
    - status
    - createdAt
    - updatedAt

rsvps/
  {rsvpId}/
    - gameId
    - userId
    - status
    - createdAt
    - updatedAt
```

### Firestore Indexes Needed
- `games`: Query by `dateTime`, `sportType`, `status`
- `rsvps`: Query by `gameId`, `userId`

---

## Project Structure

```
PickupGameOrganizer/
├── App/
│   ├── PickupGameOrganizerApp.swift
│   └── AppDelegate.swift
├── Models/
│   ├── User.swift
│   ├── Game.swift
│   ├── RSVP.swift
│   └── Enums.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── GameViewModel.swift
│   ├── ProfileViewModel.swift
│   └── MapViewModel.swift
├── Views/
│   ├── Authentication/
│   │   ├── LoginView.swift
│   │   ├── SignUpView.swift
│   │   └── ForgotPasswordView.swift
│   ├── Main/
│   │   ├── MainTabView.swift
│   │   ├── MapView.swift
│   │   └── GameListView.swift
│   ├── Game/
│   │   ├── GameDetailView.swift
│   │   ├── CreateGameView.swift
│   │   ├── EditGameView.swift
│   │   └── GameCardView.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   └── EditProfileView.swift
│   └── Components/
│       ├── CustomButton.swift
│       ├── CustomTextField.swift
│       ├── LoadingView.swift
│       └── MapAnnotationView.swift
├── Services/
│   ├── AuthService.swift
│   ├── GameService.swift
│   ├── RSVPService.swift
│   ├── NotificationService.swift
│   └── LocationService.swift
├── Utilities/
│   ├── Constants.swift
│   ├── Extensions.swift
│   └── Helpers.swift
└── Resources/
    ├── GoogleService-Info.plist
    └── Assets.xcassets
```

---

## Implementation Phases

### Phase 1.1: Project Setup & Authentication (Week 1-2)

**Steps:**
1. Create new SwiftUI project in Xcode
2. Set up Firebase project and add iOS app
3. Install Firebase SDK via Swift Package Manager
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage (for profile photos)
4. Configure Firebase in app
5. Implement authentication views:
   - Login screen
   - Signup screen
   - Forgot password
6. Create `AuthViewModel` with MVVM pattern
7. Create `AuthService` to handle Firebase Auth calls
8. Set up navigation flow (logged in vs logged out states)

**Learning Resources:**
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [SwiftUI Authentication Flow](https://www.youtube.com/results?search_query=swiftui+firebase+authentication)
- MVVM pattern in SwiftUI

**Deliverables:**
- Users can sign up, log in, and log out
- Basic profile creation on signup

---

### Phase 1.2: User Profiles (Week 2-3)

**Steps:**
1. Create `User` model
2. Create profile view UI
3. Implement profile photo upload to Firebase Storage
4. Create `ProfileViewModel`
5. Add edit profile functionality
6. Store user data in Firestore

**Key SwiftUI Concepts:**
- `@State` and `@Binding` for local state
- `@Published` and `ObservableObject` for ViewModels
- `AsyncImage` for loading images
- `PhotosPicker` for selecting photos

**Deliverables:**
- Users can view and edit their profile
- Profile photo upload works
- Data persists in Firebase

---

### Phase 1.3: Map View & Location (Week 3-4)

**Steps:**
1. Set up MapKit in SwiftUI
2. Request location permissions
3. Create `MapView` with current user location
4. Add custom annotations for game pins
5. Implement different pin colors/icons for soccer vs basketball
6. Create location picker for game creation
7. Implement geocoding (address to coordinates)

**Key Concepts:**
- `Map` view in SwiftUI
- `CoreLocation` framework
- `MKCoordinateRegion`
- Custom map annotations
- Location permissions (Info.plist configuration)

**Deliverables:**
- Map view displays with user's location
- Custom pins for different sports
- Location picker works for game creation

---

### Phase 1.4: Game Creation (Week 4-5)

**Steps:**
1. Create `Game` model
2. Build `CreateGameView` form:
   - Sport type picker
   - Location picker (map + address search)
   - Date and time picker
   - Duration picker
   - Description text field
3. Create `GameService` for Firestore operations
4. Implement create game functionality
5. Add form validation
6. Create `GameViewModel` to manage game state

**Key SwiftUI Concepts:**
- `Form` and form controls
- `Picker`, `DatePicker`, `TextField`
- Data validation
- Async/await for Firebase calls

**Deliverables:**
- Users can create games with all required fields
- Games are stored in Firestore
- Form has proper validation

---

### Phase 1.5: Game Discovery & Display (Week 5-6)

**Steps:**
1. Fetch games from Firestore
2. Display game pins on map
3. Filter games (only show upcoming, not cancelled)
4. Create `GameDetailView` to show game info
5. Add tap gesture to pins to show details
6. Create `GameCardView` component for list view
7. Build alternative list view
8. Add refresh functionality

**Key Concepts:**
- Firestore queries and real-time listeners
- `@StateObject` vs `@ObservedObject`
- List views in SwiftUI
- Navigation in SwiftUI

**Deliverables:**
- Map shows all upcoming games with pins
- Tapping pin shows game details
- List view alternative
- Real-time updates when games are added

---

### Phase 1.6: RSVP System (Week 6-7)

**Steps:**
1. Create `RSVP` model
2. Create `RSVPService` for Firestore operations
3. Add RSVP buttons to `GameDetailView` (Going/Maybe/Cancel)
4. Display list of attendees with status
5. Show attendee count on game cards and map pins
6. Handle RSVP updates (user can change from Going to Maybe)
7. Add loading states and error handling

**Key Concepts:**
- Complex Firestore queries (join-like operations)
- Managing related data
- Optimistic UI updates
- Error handling in SwiftUI

**Deliverables:**
- Users can RSVP to games
- Attendee list and count displays correctly
- RSVP updates work smoothly

---

### Phase 1.7: Game Management (Week 7-8)

**Steps:**
1. Add edit functionality for game creators
2. Implement delete game
3. Add cancel game feature
4. Only show edit/delete to game creator
5. Add "My Games" section to profile (created & attending)
6. Filter past games vs upcoming games

**Deliverables:**
- Game creators can edit, delete, or cancel their games
- Users can see their game history in profile

---

### Phase 2.1: Push Notifications (Week 8-9)

**Steps:**
1. Set up Firebase Cloud Messaging
2. Request notification permissions
3. Store FCM tokens in user documents
4. Create Cloud Functions for:
   - New game created notification
   - Game cancelled notification
   - Pre-game reminders (Cloud Scheduler)
   - RSVP notifications to game creator
5. Handle notification taps to navigate to game

**Key Concepts:**
- Firebase Cloud Messaging
- Cloud Functions (Node.js)
- Background notifications
- Deep linking in SwiftUI

**Deliverables:**
- Users receive notifications for relevant events
- Tapping notifications opens the correct game

---

### Phase 2.2: Filtering & Search (Week 9-10)

**Steps:**
1. Add filter UI (sheet or sidebar)
2. Implement sport type filter
3. Add date range filter
4. Add distance filter (within X miles)
5. Persist filter preferences
6. Add search by location/address

**Key Concepts:**
- Complex Firestore queries
- Geolocation calculations
- SwiftUI sheets and modals

**Deliverables:**
- Users can filter games by multiple criteria
- Filters persist across sessions

---

## Firebase Cloud Functions Examples

### Function: Notify on New Game
```javascript
exports.notifyNewGame = functions.firestore
  .document('games/{gameId}')
  .onCreate(async (snap, context) => {
    const game = snap.data();

    // Get all users within radius
    const users = await getUsersNearLocation(
      game.location.latitude,
      game.location.longitude,
      10 // 10 mile radius
    );

    // Send notification to each user
    const notifications = users.map(user => {
      return admin.messaging().send({
        token: user.fcmToken,
        notification: {
          title: `New ${game.sportType} game nearby!`,
          body: `${game.location.address} at ${formatDate(game.dateTime)}`
        },
        data: {
          gameId: context.params.gameId,
          type: 'new_game'
        }
      });
    });

    await Promise.all(notifications);
  });
```

### Function: Game Reminder
```javascript
exports.gameReminders = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const twoHoursFromNow = new Date(Date.now() + 2 * 60 * 60 * 1000);
    const threeHoursFromNow = new Date(Date.now() + 3 * 60 * 60 * 1000);

    // Get games starting in 2-3 hours
    const gamesSnapshot = await admin.firestore()
      .collection('games')
      .where('dateTime', '>=', twoHoursFromNow)
      .where('dateTime', '<', threeHoursFromNow)
      .where('status', '==', 'active')
      .get();

    // Send reminders to all RSVPs
    for (const gameDoc of gamesSnapshot.docs) {
      const game = gameDoc.data();
      const rsvps = await getRSVPsForGame(gameDoc.id);

      // Send to all "going" users
      const notifications = rsvps
        .filter(rsvp => rsvp.status === 'going')
        .map(async rsvp => {
          const user = await getUser(rsvp.userId);
          return admin.messaging().send({
            token: user.fcmToken,
            notification: {
              title: 'Game starting soon!',
              body: `Your ${game.sportType} game at ${game.location.address} starts at ${formatTime(game.dateTime)}`
            },
            data: {
              gameId: gameDoc.id,
              type: 'game_reminder'
            }
          });
        });

      await Promise.all(notifications);
    }
  });
```

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isOwner(userId);
      allow update, delete: if isOwner(userId);
    }

    // Games collection
    match /games/{gameId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated()
        && request.resource.data.creatorId == request.auth.uid;
      allow update, delete: if isAuthenticated()
        && resource.data.creatorId == request.auth.uid;
    }

    // RSVPs collection
    match /rsvps/{rsvpId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated()
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated()
        && resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## UI/UX Considerations

### Design Principles
1. **Simple & Clean**: Focus on core functionality
2. **Fast**: Optimize load times and interactions
3. **Intuitive**: Minimal learning curve
4. **Native Feel**: Follow iOS Human Interface Guidelines

### Color Scheme
- **Soccer**: Green accent (#34C759)
- **Basketball**: Orange accent (#FF9500)
- **Primary**: Blue (#007AFF)
- **Background**: System background (adapts to dark mode)

### Key Screens
1. **Map View (Home)**
   - Center on user location
   - Show all upcoming games as pins
   - FAB (Floating Action Button) to create game
   - Filter button in top right

2. **Game Detail**
   - Hero image/icon for sport type
   - Location with mini map
   - Date, time, duration
   - RSVP buttons prominently displayed
   - Attendee list
   - Edit/Delete for creator

3. **Create Game**
   - Step-by-step form or single scrolling form
   - Map picker for location
   - Clear validation messages

4. **Profile**
   - Profile photo at top
   - Upcoming games section
   - Past games section
   - Settings (logout, edit profile)

---

## Testing Strategy

### Unit Tests
- View model logic
- Data model encoding/decoding
- Service functions
- Date/time formatting
- Distance calculations

### Integration Tests
- Firebase authentication flow
- Firestore CRUD operations
- Real-time listener updates
- Push notification handling

### UI Tests
- Critical user flows:
  - Sign up → Create game → RSVP
  - Login → View games → Edit profile
  - Create game → Edit game → Delete game

### Manual Testing Checklist
- [ ] Authentication flows
- [ ] Game creation with all field combinations
- [ ] RSVP functionality
- [ ] Map displays correctly
- [ ] Notifications arrive
- [ ] Works in poor network conditions
- [ ] Dark mode compatibility
- [ ] Different device sizes (iPhone SE to iPhone Pro Max)

---

## Development Tips

### SwiftUI Best Practices
1. Use MVVM architecture consistently
2. Keep views small and composable
3. Use `@StateObject` for view model creation
4. Use `@ObservedObject` when passing view models
5. Extract reusable components
6. Use `.task()` for async operations on appear
7. Handle loading and error states

### Firebase Best Practices
1. Use Firestore offline persistence
2. Implement pagination for large lists
3. Use compound queries with indexes
4. Batch writes when possible
5. Handle errors gracefully
6. Use security rules properly
7. Set up Firebase Emulator for local testing

### Git Workflow
1. Use feature branches
2. Commit frequently with clear messages
3. Keep `GoogleService-Info.plist` in `.gitignore` (use different files for dev/prod)

---

## Learning Resources

### SwiftUI Fundamentals
- [Apple's SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Hacking with Swift - 100 Days of SwiftUI](https://www.hackingwithswift.com/100/swiftui)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

### Firebase
- [Firebase iOS Documentation](https://firebase.google.com/docs/ios/setup)
- [Firebase YouTube Channel](https://www.youtube.com/c/firebase)

### MapKit
- [Apple MapKit Documentation](https://developer.apple.com/documentation/mapkit)
- [Working with Maps in SwiftUI](https://developer.apple.com/documentation/mapkit/map)

### Architecture
- [MVVM in SwiftUI](https://www.youtube.com/results?search_query=mvvm+swiftui)
- [Swift Async/Await](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

---

## Estimated Timeline

| Phase | Duration | Milestone |
|-------|----------|-----------|
| Setup & Auth | 1-2 weeks | Users can sign up and log in |
| Profiles | 1 week | Users can create and edit profiles |
| Map & Location | 1 week | Map displays with location picker |
| Game Creation | 1 week | Users can create games |
| Game Discovery | 1 week | Games display on map and list |
| RSVP System | 1 week | Users can RSVP to games |
| Game Management | 1 week | Edit/delete/cancel games |
| **MVP Complete** | **7-8 weeks** | **Fully functional app** |
| Push Notifications | 1 week | Notifications working |
| Filtering | 1 week | Filter and search games |
| Polish & Testing | 1-2 weeks | Bug fixes, UI refinements |
| **Phase 2 Complete** | **10-12 weeks** | **Enhanced app** |

**Total estimated time: 10-12 weeks** (assuming 10-15 hours per week)

---

## Next Steps

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create new project
   - Add iOS app
   - Download `GoogleService-Info.plist`

2. **Set Up Xcode Project**
   - Create new SwiftUI app
   - Add Firebase SDK via Swift Package Manager
   - Configure Firebase in app

3. **Start with Authentication**
   - Build login/signup UI
   - Implement AuthViewModel
   - Test authentication flow

4. **Work Phase by Phase**
   - Complete each phase before moving to next
   - Test thoroughly after each phase
   - Keep code organized and documented

---

## Additional Features for Future

- [ ] Team balancing (suggest teams based on RSVPs)
- [ ] Integration with calendar apps
- [ ] Weather warnings
- [ ] Venue ratings/reviews
- [ ] Equipment sharing (who's bringing ball, cones, etc.)
- [ ] Game history and stats
- [ ] Achievements/badges
- [ ] Carpool coordination
- [ ] Waitlist for full games
- [ ] Recurring weekly games
- [ ] Private games (invite only)
- [ ] User blocking
- [ ] Report inappropriate behavior

---

## Questions & Support

As you build this project, here are some common issues and solutions:

### Common Issues

**Q: Firestore queries are slow**
A: Add compound indexes in Firebase Console for commonly queried fields

**Q: Map annotations not updating**
A: Make sure your Game model conforms to Identifiable and Equatable

**Q: Images not loading**
A: Check Firebase Storage rules and ensure URLs are valid

**Q: Push notifications not working**
A: Verify APNs certificate in Firebase, check device permissions, test on real device (not simulator)

**Q: SwiftUI preview not working**
A: Provide mock data to views and use preview-safe dependencies

---

## Conclusion

This implementation plan provides a structured approach to building your pickup game organizer app. Focus on completing the MVP first (Phase 1) to get a working product, then add enhanced features in Phase 2.

Remember:
- **Start small**: Get authentication working first
- **Test frequently**: Don't wait until the end
- **Learn as you go**: Each phase teaches new concepts
- **Have fun**: This is a learning project!

Good luck with your Swift and SwiftUI journey! 🚀
