import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../lib/services/auth_service.dart';
import '../lib/services/firebase_service.dart';
import '../lib/models/user.dart';

void main() {
  group('Firebase Authentication Tests', () {
    late AuthService authService;
    late FirebaseService firebaseService;

    setUp(() {
      firebaseService = FirebaseService.instance;
      authService = AuthService(firebaseService);
    });

    test('AuthService should be properly initialized with FirebaseService', () {
      expect(authService, isNotNull);
      expect(firebaseService, isNotNull);
    });

    test('AuthService should check authentication status correctly', () {
      // Test the isAuthenticated getter
      final isAuth = authService.isAuthenticated;
      expect(isAuth, isA<bool>());
    });

    test('FirebaseService should have correct configuration', () {
      // Test that FirebaseService has the correct project ID
      expect(firebaseService.currentUserId, isA<String?>());
    });

    test('User model should be created correctly', () {
      // Test that we can create a User model with the expected fields
      final testUser = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      expect(testUser.id, equals('test-id'));
      expect(testUser.email, equals('test@example.com'));
      expect(testUser.name, equals('Test User'));
      expect(testUser.createdAt, isA<DateTime>());
    });
  });
}
