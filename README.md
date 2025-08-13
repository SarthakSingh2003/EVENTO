# Evento - Event Hosting & Ticketing App

A role-based event hosting and ticketing platform built with Flutter and Firebase, designed to connect event organizers with attendees through a seamless mobile experience.

## 🎯 MVP Features

### 👤 User Roles
- **Organiser/Admin**: Create, manage, and track events
- **Moderator**: Scan tickets and manage event entry
- **Attendee/User**: Discover and purchase tickets for events

### 🔐 Authentication
- Firebase Authentication with email/password
- Role-based login system
- Secure user management

### 🗂️ Core Features by Role

#### 👨‍💼 Organiser Dashboard
- ✅ Create events with detailed information
- ✅ Manage existing events (edit/cancel/update)
- ✅ View past events with analytics
- ✅ Add/remove moderators via email
- ✅ Real-time attendee tracking

#### 🧑‍🔧 Moderator Panel
- ✅ QR code scanner for ticket validation
- ✅ Mark tickets as used to prevent re-entry
- ✅ View assigned event details
- ✅ Real-time entry management

#### 🙋‍♂️ Attendee Features
- ✅ Browse upcoming events with search and filters
- ✅ View detailed event information
- ✅ Purchase tickets securely
- ✅ QR code tickets for entry
- ✅ "My Tickets" section for ticket management
- ✅ Push notifications for event updates

## 🏗️ Project Structure

```
evento/
├── android/                 # Android platform files
├── ios/                    # iOS platform files
├── lib/
│   ├── main.dart           # App entry point
│   ├── app/
│   │   ├── app_widget.dart # Main application widget
│   │   └── theme/
│   │       └── app_theme.dart # App theme configuration
│   ├── core/
│   │   ├── services/       # Firebase services
│   │   │   ├── auth_service.dart
│   │   │   ├── firestore_service.dart
│   │   │   ├── storage_service.dart
│   │   │   └── notification_service.dart
│   │   ├── models/         # Data models
│   │   │   ├── user_model.dart
│   │   │   ├── event_model.dart
│   │   │   └── ticket_model.dart
│   │   ├── utils/          # Utilities and constants
│   │   │   ├── constants.dart
│   │   │   └── helpers.dart
│   │   └── widgets/        # Common widgets
│   │       ├── custom_button.dart
│   │       └── loading_indicator.dart
│   ├── features/           # Feature-based modules
│   │   ├── auth/           # Authentication
│   │   ├── organiser/      # Organiser features
│   │   ├── moderator/      # Moderator features
│   │   ├── attendee/       # Attendee features
│   │   └── common/         # Shared features
│   └── routes/
│       └── app_router.dart # Navigation configuration
├── test/                   # Unit and widget tests
├── pubspec.yaml           # Dependencies
└── README.md              # This file
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Firebase project setup
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd evento
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication, Firestore, Storage, and Cloud Messaging
   - Download and add the configuration files:
     - `google-services.json` for Android
     - `GoogleService-Info.plist` for iOS

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable the following services:
   - **Authentication**: Email/password sign-in
   - **Firestore Database**: For data storage
   - **Storage**: For image uploads
   - **Cloud Messaging**: For notifications

### Environment Configuration
The app uses Firebase configuration files that should be placed in:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

## 📱 Features Overview

### Authentication & User Management
- Secure email/password authentication
- Role-based access control
- User profile management
- Session management

### Event Management
- Create events with rich details
- Upload event banners
- Set ticket pricing and availability
- Real-time event updates

### Ticket System
- Secure ticket purchasing
- QR code generation for tickets
- Ticket validation system
- Purchase history tracking

### Real-time Features
- Live event updates
- Real-time attendee tracking
- Push notifications
- Instant ticket validation

## 🎨 UI/UX Features

### Modern Design
- Material Design 3 implementation
- Dark/Light theme support
- Responsive layout
- Smooth animations

### User Experience
- Intuitive navigation
- Role-based interfaces
- Loading states and error handling
- Offline capability (basic)

## 🔒 Security Features

- Firebase Authentication
- Role-based access control
- Secure data transmission
- Input validation
- Error handling

## 📊 Data Models

### User Model
- User ID, email, name
- Role (organiser, moderator, attendee)
- Profile information
- Creation and last login timestamps

### Event Model
- Event details (title, description, location)
- Date, time, and pricing
- Ticket availability
- Organiser information
- Status tracking

### Ticket Model
- Unique QR code
- Event and user association
- Purchase and usage tracking
- Validation status

## 🛠️ Technical Stack

### Frontend
- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **Provider**: State management
- **GoRouter**: Navigation

### Backend & Services
- **Firebase Authentication**: User management
- **Cloud Firestore**: Database
- **Firebase Storage**: File storage
- **Firebase Cloud Messaging**: Notifications

### Dependencies
- `firebase_core`: Firebase initialization
- `firebase_auth`: Authentication
- `cloud_firestore`: Database operations
- `firebase_storage`: File storage
- `firebase_messaging`: Push notifications
- `go_router`: Navigation
- `provider`: State management
- `qr_flutter`: QR code generation
- `qr_code_scanner`: QR code scanning
- `google_maps_flutter`: Maps integration
- `image_picker`: Image selection
- `cached_network_image`: Image caching

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📦 Building

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🔄 Future Enhancements

### Phase 2 Features
- Payment gateway integration (Stripe/Razorpay)
- Advanced analytics and reporting
- Social media integration
- Event recommendations
- Chat system for event communication
- Advanced search and filtering
- Multi-language support
- Advanced notification system

### Phase 3 Features
- AI-powered event recommendations
- Advanced analytics dashboard
- White-label solutions
- API for third-party integrations
- Advanced security features
- Performance optimizations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🎉 Acknowledgments

- Flutter team for the amazing framework
- Firebase team for the backend services
- The open-source community for various packages
- All contributors to this project

---

**Evento** - Making event management simple and efficient! 🎪
