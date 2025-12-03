import 'package:flutter_test/flutter_test.dart';
import '../lib/services/face_detector.dart';
import '../lib/config/app_config.dart';

void main() {
  group('Head Tilt Detection Tests', () {
    late FaceDetectionResult mockFaceDetectionResult;

    setUp(() {
      // Create a mock face detection result for testing
      // Note: This is a simplified test - in real implementation you'd need actual ML Kit Face objects
    });

    test('Head tilt threshold should be reduced to 8 degrees', () {
      expect(AppConfig.headTiltThresholdDegrees, equals(8));
    });

    test('Multi-indicator head tilt threshold should be 12 degrees (8 × 1.5)',
        () {
      final multiIndicatorThreshold = AppConfig.headTiltThresholdDegrees *
          AppConfig.multiIndicatorHeadTiltThreshold;
      expect(multiIndicatorThreshold, equals(12.0));
    });

    test('Confidence head tilt threshold should be 12 degrees (8 × 1.5)', () {
      final confidenceThreshold = AppConfig.headTiltThresholdDegrees *
          AppConfig.headTiltConfidenceThreshold;
      expect(confidenceThreshold, equals(12.0));
    });

    test('Severe head tilt threshold should be 9.6 degrees (8 × 1.2)', () {
      final severeThreshold = AppConfig.headTiltThresholdDegrees *
          AppConfig.severeHeadTiltThreshold;
      expect(severeThreshold, equals(9.6));
    });

    test('Enhanced shoulder tilt threshold should be 4.8 degrees (8 × 0.6)',
        () {
      final shoulderTiltThreshold = AppConfig.headTiltThresholdDegrees * 0.6;
      expect(shoulderTiltThreshold, equals(4.8));
    });

    test(
        'Enhanced severe shoulder tilt threshold should be 6.4 degrees (8 × 0.8)',
        () {
      final severeShoulderTiltThreshold =
          AppConfig.headTiltThresholdDegrees * 0.8;
      expect(severeShoulderTiltThreshold, equals(6.4));
    });

    test('Documentation values should match implementation', () {
      // Verify that the documented values match the actual implementation
      expect(AppConfig.headTiltThresholdDegrees, equals(8));
      expect(AppConfig.multiIndicatorHeadTiltThreshold, equals(1.5));
      expect(AppConfig.headTiltConfidenceThreshold, equals(1.5));
      expect(AppConfig.severeHeadTiltThreshold, equals(1.2));
    });
  });
}
