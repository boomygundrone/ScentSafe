// Firebase configuration for ScentSafe app - DISABLED (using mock service)
// Real Firebase dependencies are commented out in pubspec.yaml

/// Firebase configuration matching Driver-Fatigue-Detection system
/// Note: Firebase is disabled - using MockFirebaseService instead
class FirebaseConfig {
  // Firebase configuration values (not used when Firebase is disabled)
  static const String apiKey = "AIzaSyDZARBtvVxe10zAbMtv9D5RlCjiWkK_rNs";
  static const String appId = "1:13138269820:ios:2ec9d60e2e88f6109e9bf9";
  static const String messagingSenderId = "13138269820";
  static const String projectId = "scentsafe-17cfd";
  static const String authDomain = "scentsafe-17cfd.firebaseapp.com";
  static const String databaseUrl =
      "https://scentsafe-17cfd-default-rtdb.asia-southeast1.firebasedatabase.app";
  static const String storageBucket = "scentsafe-17cfd.firebasestorage.app";
  static const String measurementId = "G-B8K9JLMN1V";

  // Database configuration constants (matching Driver-Fatigue-Detection)
  static const String databaseUrlPath =
      "https://scentsafe-17cfd-default-rtdb.asia-southeast1.firebasedatabase.app/";

  // Real-time database paths
  static const String drowsinessStatePath = "drowsiness_state";

  // Firestore collection paths
  static const String usersCollection = "users";
  static const String recordsCollection = "records";
}
