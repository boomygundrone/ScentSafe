// Firebase configuration for ScentSafe app - FULLY ENABLED
import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration matching Driver-Fatigue-Detection system
class FirebaseConfig {
  static const FirebaseOptions current = FirebaseOptions(
    apiKey: "AIzaSyBqPg5jH8sLnSgqwT9iP2ZmGd2o4kV8a4U",
    appId: "1:107509751098449448042:android:4a5b6c7d8e9f0a1b2c3d4e",
    messagingSenderId: "107509751098449448042",
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
