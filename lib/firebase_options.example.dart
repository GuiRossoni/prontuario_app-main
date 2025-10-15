import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

// Example file. Copy this to lib/firebase_options.local.dart and fill with your
// project's values, or run `flutterfire configure` to generate firebase_options.dart
// locally (preferred for multi-platform projects).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // TODO: Replace with your own project values (do NOT commit real keys)
    return const FirebaseOptions(
      apiKey: 'YOUR_API_KEY',
      appId: '1:YOUR_SENDER_ID:android:YOUR_APP_ID',
      messagingSenderId: 'YOUR_SENDER_ID',
      projectId: 'YOUR_PROJECT_ID',
      storageBucket: 'YOUR_STORAGE_BUCKET',
    );
  }
}
