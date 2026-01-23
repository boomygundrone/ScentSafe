// Firebase integration disabled - using mock service instead
// Real Firebase dependencies are commented out in pubspec.yaml
// This service now uses MockFirebaseService for compatibility

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/firebase_config.dart';
import 'mock_firebase_service.dart';

/// Service for managing Firebase operations
/// Note: This is a stub service that uses MockFirebaseService
/// Real Firebase integration is disabled for compatibility
class FirebaseService {
  static FirebaseService? _instance;

  // Private constructor for singleton
  FirebaseService._internal();

  /// Get singleton instance
  static FirebaseService get instance {
    _instance ??= FirebaseService._internal();
    return _instance!;
  }

  // Scoring weights (matching Driver-Fatigue-Detection)
  static const double _blinkWeight = 0.4;
  static const double _yawnWeight = 0.3;
  static const double _headTiltWeight = 0.3;

  // Thresholds (matching Driver-Fatigue-Detection)
  static const double _earThreshold = 0.25;
  static const double _marThreshold = 0.5;
  static const double _headTiltThreshold = 15.0;
  static const int _earConsecFrames = 3;

  late SharedPreferences _prefs;

  /// Initialize Firebase services with service account authentication
  Future<void> initialize() async {
    try {
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      print('📊 Project ID: ${FirebaseConfig.projectId}');
      print('🔗 Database URL: ${FirebaseConfig.databaseUrl}');

      // Delegate to mock service
      await MockFirebaseService.instance.initialize();

      print('✅ Firebase initialized successfully (using mock service)');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Authenticate user (matching Driver-Fatigue-Detection pattern)
  Future<String?> authenticateUser(String email, String password) async {
    try {
      // Delegate to mock service
      return await MockFirebaseService.instance
          .authenticateUser(email, password);
    } catch (e) {
      print('❌ Unexpected authentication error: $e');
      rethrow;
    }
  }

  /// Update current drowsiness state in Firebase Realtime Database
  /// (matching Driver-Fatigue-Detection implementation)
  Future<void> updateDrowsinessState(String state) async {
    try {
      print('🔄 Drowsiness state updated to: $state (mock)');
    } catch (e) {
      print('❌ Failed to update drowsiness state: $e');
    }
  }

  /// Store drowsiness data in Firestore
  /// (matching Driver-Fatigue-Detection implementation)
  Future<void> storeDrowsinessData({
    required int blinkCount,
    required int yawnCount,
    required double drowsinessScore,
    required double headTiltAngle,
    required double earValue,
    required double marValue,
  }) async {
    try {
      print(
          '💾 Drowsiness data stored: Score=$drowsinessScore, Blinks=$blinkCount, Yawns=$yawnCount (mock)');
    } catch (e) {
      print('❌ Failed to store drowsiness data: $e');
    }
  }

  /// Fetch records within given time period
  /// (matching Driver-Fatigue-Detection implementation)
  Future<List<Map<String, dynamic>>> fetchRecords(
      String userId, Duration timePeriod) async {
    try {
      print('📊 Fetched records for last ${timePeriod.inDays} days (mock)');
      return [];
    } catch (e) {
      print('❌ Failed to fetch records: $e');
      return [];
    }
  }

  /// Convenience method to fetch records for different time periods
  Future<List<Map<String, dynamic>>> getLastMonthRecords() async {
    return await fetchRecords('mock_user', const Duration(days: 30));
  }

  Future<List<Map<String, dynamic>>> getLast14DaysRecords() async {
    return await fetchRecords('mock_user', const Duration(days: 14));
  }

  Future<List<Map<String, dynamic>>> getLast7DaysRecords() async {
    return await fetchRecords('mock_user', const Duration(days: 7));
  }

  Future<List<Map<String, dynamic>>> getLast2HoursRecords() async {
    return await fetchRecords('mock_user', const Duration(hours: 2));
  }

  /// Get current authenticated user
  dynamic get currentUser => null;

  /// Get current user's ID
  String? get currentUserId => null;

  /// Get current user's email
  String? get currentUserEmail => null;

  /// Set up real-time database listener for drowsiness state
  void listenToDrowsinessState(Function(Map<String, dynamic>) callback) {
    // Mock implementation - does nothing
  }

  /// Calculate drowsiness score using same algorithm as Driver-Fatigue-Detection
  double calculateDrowsinessScore(
      int blinkCount, int yawnCount, double headTiltAngle) {
    final blinkScore = (blinkCount / 25.0).clamp(0.0, 1.0) * _blinkWeight * 100;
    final yawnScore = (yawnCount / 3.0).clamp(0.0, 1.0) * _yawnWeight * 100;
    final headTiltScore =
        (headTiltAngle.abs() / _headTiltThreshold).clamp(0.0, 1.0) *
            _headTiltWeight *
            100;

    return blinkScore + yawnScore + headTiltScore;
  }

  /// Get drowsiness state based on score (matching Driver-Fatigue-Detection logic)
  String getDrowsinessState(double score) {
    if (score < 40) {
      return 'No Drowsiness';
    } else if (score <= 50) {
      return 'Warning';
    } else {
      return 'Drowsiness';
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => false;

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await MockFirebaseService.instance.signOut();
      print('👋 User signed out successfully');
    } catch (e) {
      print('❌ Sign out failed: $e');
    }
  }

  /// Stream of drowsiness state changes from real-time database
  Stream<Map<String, dynamic>?> get drowsinessStateStream {
    return const Stream.empty();
  }

  /// Stream of user's detection records from Firestore
  Stream<List<Map<String, dynamic>>> getUserRecordsStream(String userId) {
    try {
      return const Stream.empty();
    } catch (e) {
      print('❌ Failed to create records stream: $e');
      return const Stream.empty();
    }
  }

  /// Clean up resources
  void dispose() {
    // Mock implementation - does nothing
  }
}
