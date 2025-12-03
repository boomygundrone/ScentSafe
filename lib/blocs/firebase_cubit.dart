import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/firebase_service.dart';

/// Firebase Cubit for managing Firebase-related state
/// Handles authentication, data storage, and real-time updates
class FirebaseCubit extends Cubit<FirebaseState> {
  final FirebaseService _firebaseService;
  
  FirebaseCubit(this._firebaseService) : super(FirebaseInitial());

  /// Initialize Firebase
  Future<void> initializeFirebase() async {
    emit(FirebaseLoading());
    try {
      await _firebaseService.initialize();
      emit(FirebaseLoaded());
    } catch (e) {
      emit(FirebaseError(e.toString()));
    }
  }

  /// Authenticate user
  Future<void> authenticateUser(String email, String password) async {
    emit(FirebaseLoading());
    try {
      final userId = await _firebaseService.authenticateUser(email, password);
      if (userId != null) {
        emit(FirebaseAuthenticated(userId));
      } else {
        emit(FirebaseError('Authentication failed'));
      }
    } catch (e) {
      emit(FirebaseError(e.toString()));
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    emit(FirebaseLoading());
    try {
      await _firebaseService.signOut();
      emit(FirebaseInitial());
    } catch (e) {
      emit(FirebaseError(e.toString()));
    }
  }

  /// Get user records
  Future<void> fetchUserRecords(String userId, Duration period) async {
    emit(FirebaseLoading());
    try {
      final records = await _firebaseService.fetchRecords(userId, period);
      emit(FirebaseRecordsLoaded(records));
    } catch (e) {
      emit(FirebaseError(e.toString()));
    }
  }

  /// Get current user
  String? get currentUserId => _firebaseService.currentUser?.uid;

  /// Get drowsiness state stream
  Stream<Map<String, dynamic>?> get drowsinessStateStream =>
      _firebaseService.drowsinessStateStream;

  /// Get user records stream
  Stream<List<Map<String, dynamic>>> getUserRecordsStream(String userId) => 
      _firebaseService.getUserRecordsStream(userId);
}

/// Firebase states
abstract class FirebaseState {}

class FirebaseInitial extends FirebaseState {}

class FirebaseLoading extends FirebaseState {}

class FirebaseLoaded extends FirebaseState {}

class FirebaseAuthenticated extends FirebaseState {
  final String userId;
  FirebaseAuthenticated(this.userId);
}

class FirebaseRecordsLoaded extends FirebaseState {
  final List<Map<String, dynamic>> records;
  FirebaseRecordsLoaded(this.records);
}

class FirebaseError extends FirebaseState {
  final String message;
  FirebaseError(this.message);
}