import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseService _firebaseService;

  AuthService(this._firebaseService);

  /// Sign in with email and password using Firebase Authentication
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
        final auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          print('✅ Sign in successful for: ${firebaseUser.email}');
          return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ??
                firebaseUser.email?.split('@')[0] ??
                'User',
            createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          );
        }
      }

      throw Exception('Authentication failed: No user ID returned');
    } on auth.FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      print('❌ Unexpected sign in error: $e');
      throw Exception('Authentication failed: $e');
    }
  }

  /// Sign up with email, password, and name using Firebase Authentication
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
      // First create the user account
      auth.UserCredential result =
          await auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Update the user's display name
        await result.user!.updateDisplayName(name);
        await result.user!.reload();

        // Get the updated user
        final auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;

        if (firebaseUser != null) {
          print('✅ Registration successful for: ${firebaseUser.email}');
          return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? name,
            createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          );
        }
      }

      throw Exception('User registration failed: No user created');
    } on auth.FirebaseAuthException catch (e) {
      print('❌ Firebase Registration Error: ${e.code} - ${e.message}');
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      print('❌ Unexpected registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  /// Sign out using Firebase Authentication
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

  /// Get current user from Firebase Authentication
  Future<User?> getCurrentUser() async {
    try {
      final auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        print('👤 Current user found: ${firebaseUser.email}');
        return User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              'User',
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        );
      }
      print('👤 No current user found');
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    return auth.FirebaseAuth.instance.currentUser != null;
  }

  /// Get Firebase error messages in user-friendly format
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
