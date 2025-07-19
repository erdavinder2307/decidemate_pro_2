import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Utility class to generate platform-specific configuration files
/// from environment variables. This is useful for platforms that
/// require specific config files (like iOS GoogleService-Info.plist)
class ConfigGenerator {
  
  /// Generate iOS GoogleService-Info.plist from environment variables
  static Future<void> generateiOSConfig() async {
    await dotenv.load(fileName: ".env");
    
    final plistContent = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>${dotenv.env['FIREBASE_IOS_API_KEY']}</string>
	<key>GCM_SENDER_ID</key>
	<string>${dotenv.env['FIREBASE_MESSAGING_SENDER_ID']}</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>${dotenv.env['FIREBASE_IOS_BUNDLE_ID']}</string>
	<key>PROJECT_ID</key>
	<string>${dotenv.env['FIREBASE_PROJECT_ID']}</string>
	<key>STORAGE_BUCKET</key>
	<string>${dotenv.env['FIREBASE_STORAGE_BUCKET']}</string>
	<key>IS_ADS_ENABLED</key>
	<false></false>
	<key>IS_ANALYTICS_ENABLED</key>
	<false></false>
	<key>IS_APPINVITE_ENABLED</key>
	<true></true>
	<key>IS_GCM_ENABLED</key>
	<true></true>
	<key>IS_SIGNIN_ENABLED</key>
	<true></true>
	<key>GOOGLE_APP_ID</key>
	<string>${dotenv.env['FIREBASE_IOS_APP_ID']}</string>
</dict>
</plist>''';

    final file = File('ios/Runner/GoogleService-Info.plist');
    await file.writeAsString(plistContent);
    print('✅ Generated ios/Runner/GoogleService-Info.plist');
  }

  /// Generate Android google-services.json from environment variables
  static Future<void> generateAndroidConfig() async {
    await dotenv.load(fileName: ".env");
    
    final jsonContent = '''{
  "project_info": {
    "project_number": "${dotenv.env['FIREBASE_MESSAGING_SENDER_ID']}",
    "project_id": "${dotenv.env['FIREBASE_PROJECT_ID']}",
    "storage_bucket": "${dotenv.env['FIREBASE_STORAGE_BUCKET']}"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "${dotenv.env['FIREBASE_ANDROID_APP_ID']}",
        "android_client_info": {
          "package_name": "com.amazingappsdev.decidematepro2"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "${dotenv.env['FIREBASE_ANDROID_API_KEY']}"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}''';

    final file = File('android/app/google-services.json');
    await file.writeAsString(jsonContent);
    print('✅ Generated android/app/google-services.json');
  }

  /// Generate all platform configs
  static Future<void> generateAllConfigs() async {
    print('🔧 Generating platform-specific configuration files...');
    
    try {
      await generateiOSConfig();
      await generateAndroidConfig();
      print('✅ All configuration files generated successfully!');
      print('📝 Note: These files are excluded from version control for security.');
    } catch (e) {
      print('❌ Error generating config files: $e');
      print('Make sure your .env file is properly configured.');
    }
  }
}

/// Run this script to generate platform-specific config files
/// Usage: dart lib/utils/config_generator.dart
void main() async {
  await ConfigGenerator.generateAllConfigs();
}
