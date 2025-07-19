# DecideMate Pro

A Flutter decision-making app with Firebase backend integration.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (latest stable version)
- Firebase account and project
- Android Studio / Xcode for mobile development

### Environment Setup

This project uses environment variables to securely manage Firebase configuration. Follow these steps:

#### 1. Automated Setup (Recommended)
```bash
# Run the setup script
./setup_env.sh
```

#### 2. Manual Setup
```bash
# Copy the environment template
cp .env.example .env

# Edit .env file with your Firebase configuration
# Get values from Firebase Console > Project Settings > General
```

#### 3. Firebase Configuration
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project > Project Settings > General
3. Scroll to "Your apps" section
4. Copy configuration values for each platform:
   - **Web**: API Key, App ID, Measurement ID
   - **Android**: API Key, App ID  
   - **iOS**: API Key, App ID, Bundle ID
   - **macOS**: API Key, App ID, Bundle ID (if applicable)
   - **Windows**: API Key, App ID, Measurement ID

#### 4. Install Dependencies & Run
```bash
flutter pub get
flutter run
```

## 🔒 Security

- **Never commit** `.env` file to version control
- Use `.env.example` as a template for team members
- Rotate API keys regularly
- Use separate Firebase projects for development/production

## 📱 Platform Support

- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ Windows
- ✅ macOS

## 🛠 Development

### Project Structure
```
lib/
├── screens/          # UI screens
├── services/         # Firebase services
├── firebase_options.dart  # Firebase configuration (uses .env)
└── main.dart        # App entry point
```

### Environment Variables
Key environment variables used:
- `FIREBASE_PROJECT_ID` - Your Firebase project ID
- `FIREBASE_WEB_API_KEY` - Web platform API key
- `FIREBASE_ANDROID_API_KEY` - Android platform API key  
- `FIREBASE_IOS_API_KEY` - iOS platform API key
- And more... (see `.env.example`)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
