/// Mock FirebaseService for testing without Firebase dependencies
/// This allows the app to build and run when Firebase is not configured
class MockFirebaseService {
  static final MockFirebaseService _instance = MockFirebaseService._internal();
  static MockFirebaseService get instance => _instance;

  MockFirebaseService._internal();

  /// Mock authenticate user - returns null (no user)
  Future<String?> authenticateUser(String email, String password) async {
    print(
        '⚠️  MockFirebaseService: authenticateUser called (Firebase disabled)');
    return null;
  }

  /// Mock sign out - does nothing
  Future<void> signOut() async {
    print('⚠️  MockFirebaseService: signOut called (Firebase disabled)');
  }

  /// Mock initialize - does nothing
  Future<void> initialize() async {
    print('⚠️  MockFirebaseService: initialize called (Firebase disabled)');
  }
}
