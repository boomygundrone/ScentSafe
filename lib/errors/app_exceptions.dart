/// Custom exception types for better error handling and debugging
/// Provides structured error information instead of generic strings

import 'package:flutter/foundation.dart';

/// Base application exception
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('${runtimeType}');
    if (code != null) {
      buffer.write(' [${code!}]');
    }
    buffer.write(': ${message}');
    if (originalError != null) {
      buffer.write('\nOriginal Error: ${originalError}');
    }
    return buffer.toString();
  }
}

/// Authentication related exceptions
class AuthenticationException extends AppException {
  AuthenticationException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Camera related exceptions
class CameraException extends AppException {
  CameraException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Detection related exceptions
class DetectionException extends AppException {
  DetectionException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Bluetooth related exceptions
class BluetoothException extends AppException {
  BluetoothException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Firebase related exceptions
class FirebaseException extends AppException {
  FirebaseException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Memory management exceptions
class MemoryException extends AppException {
  MemoryException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Service initialization exceptions
class ServiceInitializationException extends AppException {
  ServiceInitializationException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Validation exceptions
class ValidationException extends AppException {
  ValidationException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

/// Generic error handler utility
class ErrorHandler {
  /// Convert any exception to a structured AppException
  static AppException handle(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }

    // Handle specific error types
    if (error.toString().toLowerCase().contains('camera')) {
      return CameraException(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error.toString().toLowerCase().contains('bluetooth')) {
      return BluetoothException(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error.toString().toLowerCase().contains('firebase') ||
        error.toString().toLowerCase().contains('auth')) {
      return FirebaseException(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error.toString().toLowerCase().contains('detection') ||
        error.toString().toLowerCase().contains('face')) {
      return DetectionException(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Generic application exception
    return ValidationException(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error with structured information
  static void logError(AppException error) {
    final timestamp = error.timestamp.toIso8601String();
    final errorType = error.runtimeType.toString();
    final message = error.message;
    final code = error.code ?? 'UNKNOWN';

    // Use debugPrint for better debugging experience
    debugPrint('=== ERROR REPORT ===');
    debugPrint('Timestamp: $timestamp');
    debugPrint('Type: $errorType');
    debugPrint('Code: $code');
    debugPrint('Message: $message');
    if (error.originalError != null) {
      debugPrint('Original: ${error.originalError}');
    }
    if (error.stackTrace != null) {
      debugPrint('Stack: ${error.stackTrace}');
    }
    debugPrint('=== END ERROR REPORT ===');
  }
}