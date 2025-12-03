import 'package:flutter_test/flutter_test.dart';
import 'package:scentsafe/services/auth_service.dart';
import 'package:scentsafe/models/user.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    group('Sign In', () {
      test('signIn with valid credentials returns user', () async {
        final user = await authService.signIn('test@example.com', 'password');

        expect(user, isA<User>());
        expect(user.email, 'test@example.com');
        expect(user.name, 'Mock User');
        expect(user.id, isNotEmpty);
      });

      test('signIn with empty credentials throws exception', () async {
        expect(
          () => authService.signIn('', ''),
          throwsA(isA<Exception>()),
        );
      });

      test('signIn simulates network delay', () async {
        final stopwatch = Stopwatch()..start();
        await authService.signIn('test@example.com', 'password');
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(1000));
      });
    });

    group('Sign Up', () {
      test('signUp with valid data creates new user', () async {
        final user = await authService.signUp('new@example.com', 'password', 'New User');

        expect(user, isA<User>());
        expect(user.email, 'new@example.com');
        expect(user.name, 'New User');
        expect(user.id, startsWith('mock_user_id_'));
      });

      test('signUp with empty data throws exception', () async {
        expect(
          () => authService.signUp('', '', ''),
          throwsA(isA<Exception>()),
        );
      });

      test('signUp generates unique user IDs', () async {
        final user1 = await authService.signUp('user1@example.com', 'password', 'User 1');
        final user2 = await authService.signUp('user2@example.com', 'password', 'User 2');

        expect(user1.id, isNot(equals(user2.id)));
      });
    });

    group('Authentication State', () {
      test('initial state is not authenticated', () {
        expect(authService.isAuthenticated, false);
      });

      test('signIn updates authentication state', () async {
        await authService.signIn('test@example.com', 'password');
        expect(authService.isAuthenticated, true);
      });

      test('signOut clears authentication state', () async {
        await authService.signIn('test@example.com', 'password');
        expect(authService.isAuthenticated, true);

        await authService.signOut();
        expect(authService.isAuthenticated, false);
      });

      test('getCurrentUser returns current user after sign in', () async {
        await authService.signIn('test@example.com', 'password');
        final user = await authService.getCurrentUser();

        expect(user, isA<User>());
        expect(user?.email, 'test@example.com');
      });

      test('getCurrentUser returns null when not signed in', () async {
        final user = await authService.getCurrentUser();
        expect(user, isNull);
      });

      test('getCurrentUser simulates network delay', () async {
        final stopwatch = Stopwatch()..start();
        await authService.getCurrentUser();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(300));
      });
    });
  });

  group('User Model', () {
    test('creates user with all required fields', () {
      final user = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      expect(user.id, 'test-id');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.createdAt, isA<DateTime>());
    });

    test('serializes to JSON correctly', () {
      final timestamp = DateTime.parse('2023-01-01T10:00:00Z');
      final user = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: timestamp,
      );

      final json = user.toJson();
      expect(json['id'], 'test-id');
      expect(json['email'], 'test@example.com');
      expect(json['name'], 'Test User');
      expect(json['createdAt'], '2023-01-01T10:00:00.000Z');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'name': 'Test User',
        'createdAt': '2023-01-01T10:00:00.000Z',
      };

      final user = User.fromJson(json);
      expect(user.id, 'test-id');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.createdAt, DateTime.parse('2023-01-01T10:00:00Z'));
    });

    test('round trip serialization works', () {
      final original = User(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      final json = original.toJson();
      final reconstructed = User.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.email, original.email);
      expect(reconstructed.name, original.name);
      expect(reconstructed.createdAt, original.createdAt);
    });
  });
}