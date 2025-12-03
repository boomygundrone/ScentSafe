// Complete Firebase integration matching Driver-Fatigue-Detection system
// Includes: Real-time database, Firestore, Authentication, and user data separation

import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/firebase_config.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static auth.User? _currentUser;
  static rtdb.DatabaseReference? _drowsinessStateRef;
  static fs.CollectionReference? _userRecordsRef;

  // Private constructor for singleton
  FirebaseService._internal();

  /// Get singleton instance
  static FirebaseService get instance {
    _instance ??= FirebaseService._internal();
    return _instance!;
  }

  // Firebase configuration constants
  static const String _serviceAccountKeyPath =
      'assets/firebase/service_account_key.json';

  // Scoring weights (matching Driver-Fatigue-Detection)
  static const double _blinkWeight = 0.4;
  static const double _yawnWeight = 0.3;
  static const double _headTiltWeight = 0.3;

  // Thresholds (matching Driver-Fatigue-Detection)
  static const double _earThreshold = 0.25;
  static const double _marThreshold = 0.5;
  static const double _headTiltThreshold = 15.0;
  static const int _earConsecFrames = 3;

  late FirebaseOptions _firebaseOptions;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Initialize Firebase services with service account authentication
  Future<void> initialize() async {
    try {
      // Load service account key from assets
      String serviceAccountJson = await _loadServiceAccountKey();

      // Use the centralized Firebase configuration
      _firebaseOptions = FirebaseConfig.current;

      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        // Initialize Firebase with options only if not already initialized
        await Firebase.initializeApp(options: _firebaseOptions);
        print('✅ Firebase initialized successfully');
      } else {
        print('✅ Firebase already initialized, skipping initialization');
      }

      print('📊 Project ID: ${FirebaseConfig.projectId}');
      print('🔗 Database URL: ${FirebaseConfig.databaseUrl}');

      // Initialize real-time database reference
      _drowsinessStateRef = rtdb.FirebaseDatabase.instance
          .ref()
          .child(FirebaseConfig.drowsinessStatePath);
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Load service account key from assets
  Future<String> _loadServiceAccountKey() async {
    try {
      return await rootBundle.loadString(_serviceAccountKeyPath);
    } catch (e) {
      print('⚠️  Service account key not found, using default configuration');
      return '{}';
    }
  }

  /// Authenticate user (matching Driver-Fatigue-Detection pattern)
  Future<String?> authenticateUser(String email, String password) async {
    try {
      auth.UserCredential result =
          await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        _currentUser = result.user!;
        _userRecordsRef = fs.FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('records');

        print(
            '✅ User authenticated: ${_currentUser!.email} (${_currentUser!.uid})');
        return _currentUser!.uid;
      }
    } on auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('👤 User not found, creating new user...');
        return await _createUser(email, password);
      } else {
        print('❌ Authentication failed: ${e.message}');
        rethrow;
      }
    } catch (e) {
      print('❌ Unexpected authentication error: $e');
      rethrow;
    }

    return null;
  }

  /// Create new user (matching Driver-Fatigue-Detection pattern)
  Future<String?> _createUser(String email, String password) async {
    try {
      auth.UserCredential result =
          await auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        _currentUser = result.user!;
        _userRecordsRef = fs.FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('records');

        print(
            '🆕 New user created: ${_currentUser!.email} (${_currentUser!.uid})');
        return _currentUser!.uid;
      }
    } catch (e) {
      print('❌ User creation failed: $e');
      rethrow;
    }

    return null;
  }

  /// Update current drowsiness state in Firebase Realtime Database
  /// (matching Driver-Fatigue-Detection implementation)
  Future<void> updateDrowsinessState(String state) async {
    try {
      if (_drowsinessStateRef == null) {
        print('⚠️  Drowsiness state reference not initialized');
        return;
      }

      final data = {
        'state': state,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'userId': _currentUser?.uid ?? 'anonymous',
      };

      await _drowsinessStateRef!.set(data);
      print('🔄 Drowsiness state updated to: $state');
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
      if (_currentUser == null) {
        print('⚠️  No authenticated user for data storage');
        return;
      }

      if (_userRecordsRef == null) {
        print('⚠️  User records reference not initialized');
        return;
      }

      final record = {
        'timestamp': fs.FieldValue.serverTimestamp(),
        'blinkCount': blinkCount,
        'yawnCount': yawnCount,
        'drowsinessScore': drowsinessScore,
        'headTiltAngle': headTiltAngle,
        'earValue': earValue,
        'marValue': marValue,
        'date': DateTime.now()
            .toIso8601String()
            .split('T')[0], // For easier queries
      };

      await _userRecordsRef!.add(record);
      print(
          '💾 Drowsiness data stored: Score=$drowsinessScore, Blinks=$blinkCount, Yawns=$yawnCount');
    } catch (e) {
      print('❌ Failed to store drowsiness data: $e');
    }
  }

  /// Fetch records within given time period
  /// (matching Driver-Fatigue-Detection implementation)
  Future<List<Map<String, dynamic>>> fetchRecords(
      String userId, Duration timePeriod) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(timePeriod);

      fs.Query query = fs.FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('records')
          .where('timestamp',
              isGreaterThanOrEqualTo: fs.Timestamp.fromDate(startTime))
          .orderBy('timestamp', descending: true);

      fs.QuerySnapshot snapshot = await query.get();

      List<Map<String, dynamic>> records = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      print(
          '📊 Fetched ${records.length} records for the last ${timePeriod.inDays} days');
      return records;
    } catch (e) {
      print('❌ Failed to fetch records: $e');
      return [];
    }
  }

  /// Convenience method to fetch records for different time periods
  Future<List<Map<String, dynamic>>> getLastMonthRecords() async {
    if (_currentUser == null) return [];
    return await fetchRecords(_currentUser!.uid, const Duration(days: 30));
  }

  Future<List<Map<String, dynamic>>> getLast14DaysRecords() async {
    if (_currentUser == null) return [];
    return await fetchRecords(_currentUser!.uid, const Duration(days: 14));
  }

  Future<List<Map<String, dynamic>>> getLast7DaysRecords() async {
    if (_currentUser == null) return [];
    return await fetchRecords(_currentUser!.uid, const Duration(days: 7));
  }

  Future<List<Map<String, dynamic>>> getLast2HoursRecords() async {
    if (_currentUser == null) return [];
    return await fetchRecords(_currentUser!.uid, const Duration(hours: 2));
  }

  /// Get current authenticated user
  auth.User? get currentUser => _currentUser;

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await auth.FirebaseAuth.instance.signOut();
      _currentUser = null;
      _userRecordsRef = null;
      print('👋 User signed out successfully');
    } catch (e) {
      print('❌ Sign out failed: $e');
    }
  }

  /// Stream of drowsiness state changes from real-time database
  Stream<Map<String, dynamic>?> get drowsinessStateStream {
    if (_drowsinessStateRef == null) {
      return const Stream.empty();
    }

    return _drowsinessStateRef!.onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  /// Stream of user's detection records from Firestore
  Stream<List<Map<String, dynamic>>> getUserRecordsStream(String userId) {
    try {
      return fs.FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('records')
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to last 50 records for performance
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('❌ Failed to create records stream: $e');
      return const Stream.empty();
    }
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
  bool get isAuthenticated => _currentUser != null;

  /// Get current user's ID
  String? get currentUserId => _currentUser?.uid;

  /// Get current user's email
  String? get currentUserEmail => _currentUser?.email;

  /// Set up real-time database listener for drowsiness state
  void listenToDrowsinessState(Function(Map<String, dynamic>) callback) {
    if (_drowsinessStateRef == null) return;

    _drowsinessStateRef!.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        callback(data);
      }
    });
  }

  /// Clean up resources
  void dispose() {
    _drowsinessStateRef = null;
    _userRecordsRef = null;
  }
}
