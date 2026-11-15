/// Template for application secrets and configuration.
/// 
/// Instructions:
/// 1. Copy this file to `lib/config/secrets.dart`:
///    cp lib/config/secrets.example.dart lib/config/secrets.dart
/// 2. Fill in your own Gmail address and 16-character Google App Password.
/// 3. Fill in your Firebase API key.
class AppSecrets {
  /// Sender Gmail address used for sending 6-digit verification OTPs and reset notifications
  static const String gmailSenderEmail = 'your_sender_email@gmail.com';

  /// 16-character Google App Password generated from Google Account Security settings
  static const String gmailAppPassword = 'your_16_char_google_app_password';

  /// Firebase Client API Key
  static const String firebaseApiKey = 'AIzaSy_YOUR_FIREBASE_API_KEY_HERE';

  /// Optional Google Apps Script Relay URL (leave empty if using direct SMTP)
  static const String appsScriptWebhookUrl = '';
}
