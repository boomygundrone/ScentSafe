import '../models/user.dart';
import 'mock_firebase_service.dart';

class AuthService {
  final dynamic _firebaseService;

  AuthService(this._firebaseService);

  /// Sign in with email and password using mock authentication
  Future<User> signIn(String email, String password) async {
    // Validate input
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception('Email and password cannot be empty');
    }

    if (!_isValidEmail(email)) {
      throw Exception('Please enter a valid email address');
    }

    try {
      print('🔐 Attempting sign in for: $email');
      final userId = await _firebaseService.authenticateUser(email, password);

      if (userId != null) {
        print('✅ Sign in successful for: $email');
        return User(
          id: userId ?? 'mock-id',
          email: email,
          name: email.split('@')[0] ?? 'User',
          createdAt: DateTime.now(),
        );
      }

      throw Exception('Authentication failed: No user ID returned');
    } catch (e) {
      print('❌ Unexpected sign in error: $e');
      throw Exception('Authentication failed: $e');
    }
  }

  /// Sign up with email, password, and name using mock authentication
  Future<User> signUp(String email, String password, String name) async {
    // Validate input
    if (email.trim().isEmpty ||
        password.trim().isEmpty ||
        name.trim().isEmpty) {
      throw Exception('All fields are required');
    }

    if (!_isValidEmail(email)) {
      throw Exception('Please enter a valid email address');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long');
    }

    try {
      print('🔐 Attempting user registration for: $email');
      // Mock user creation - return mock user
      print('✅ Registration successful for: $email');
      return User(
        id: 'mock-id',
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Unexpected registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  /// Sign out using mock authentication
  Future<void> signOut() async {
    try {
      print('🔐 Signing out user...');
      await _firebaseService.signOut();
      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Sign out error: $e');
      throw Exception('Sign out failed: $e');
    }
  }

  /// Get current user from mock authentication
  Future<User?> getCurrentUser() async {
    try {
      print('👤 Getting current user...');
      // Mock current user - return null (no user logged in)
      print('👤 No current user found');
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    // Mock authentication - always return false
    return false;
  }

  /// Get error messages in user-friendly format
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled.';
      case 'invalid-credential':
        return 'Invalid login credentials.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication error: $errorCode';
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
