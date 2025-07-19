# Firebase Configuration Setup Guide

## Security Notice
This project uses Firebase for backend services. To protect sensitive API keys and configuration data, the actual Firebase configuration files are not included in the repository.

## Setup Instructions

### 1. Firebase Configuration for Dart/Flutter

1. Copy `lib/firebase_options_template.dart` to `lib/firebase_options.dart`
2. Replace all placeholder values with your actual Firebase configuration:
   - Get your configuration from the Firebase Console
   - Go to Project Settings > General > Your Apps
   - Copy the configuration values for each platform

### 2. iOS Configuration

1. Copy `ios/Runner/GoogleService-Info-template.plist` to `ios/Runner/GoogleService-Info.plist`
2. Download the actual `GoogleService-Info.plist` from Firebase Console:
   - Go to Project Settings > General > Your Apps
   - Click on your iOS app
   - Download the `GoogleService-Info.plist` file
   - Replace the template file with the downloaded file

### 3. Android Configuration

1. Download `google-services.json` from Firebase Console:
   - Go to Project Settings > General > Your Apps  
   - Click on your Android app
   - Download the `google-services.json` file
   - Place it in `android/app/google-services.json`

### 4. macOS Configuration (if applicable)

1. Download the macOS `GoogleService-Info.plist` from Firebase Console
2. Place it in `macos/Runner/GoogleService-Info.plist`

## Important Security Notes

- **Never commit** the actual configuration files to version control
- The `.gitignore` file is configured to exclude these sensitive files
- Each developer and environment should have their own Firebase project configuration
- For production deployments, use CI/CD environment variables or secure secret management

## Troubleshooting

If you encounter Firebase initialization errors:
1. Verify all configuration files are in place
2. Check that API keys are correctly formatted (no extra spaces/characters)
3. Ensure the bundle IDs match between your app and Firebase console
4. Verify the project ID is consistent across all configuration files

## API Key Rotation

If API keys are ever exposed:
1. Immediately regenerate API keys in Firebase Console
2. Update all configuration files with new keys
3. Redeploy applications with new configuration
4. Consider implementing API key restrictions in Firebase Console
