// Firebase configuration for ScentSafe app - FULLY ENABLED
import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration matching Driver-Fatigue-Detection system
class FirebaseConfig {
  static const FirebaseOptions current = FirebaseOptions(
    apiKey: "AIzaSyDZARBtvVxe10zAbMtv9D5RlCjiWkK_rNs",
    appId: "1:13138269820:ios:2ec9d60e2e88f6109e9bf9",
    messagingSenderId: "13138269820",
    projectId: "scentsafe-17cfd",
    authDomain: "scentsafe-17cfd.firebaseapp.com",
    databaseURL:
        "https://scentsafe-17cfd-default-rtdb.asia-southeast1.firebasedatabase.app",
    storageBucket: "scentsafe-17cfd.firebasestorage.app",
    measurementId: "G-B8K9JLMN1V", // Sample measurement ID
  );

  // Database configuration constants (matching Driver-Fatigue-Detection)
  static const String projectId = "scentsafe-17cfd";
  static const String databaseUrl =
      "https://scentsafe-17cfd-default-rtdb.asia-southeast1.firebasedatabase.app/";

  // Real-time database paths
  static const String drowsinessStatePath = "drowsiness_state";

  // Firestore collection paths
  static const String usersCollection = "users";
  static const String recordsCollection = "records";
}
