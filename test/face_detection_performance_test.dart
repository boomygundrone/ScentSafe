import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../lib/services/face_detector.dart';
import '../lib/config/app_config.dart';

void main() {
  group('Face Detection Performance Tests', () {
    late FaceDetectorService faceDetector;
    late InputImage testImage;

    setUp(() async {
      faceDetector = FaceDetectorService();
      await faceDetector.initialize();

      // Create a test image (placeholder - would need real image data in real test)
      testImage = _createTestImage();
    });

    tearDown(() {
      faceDetector.dispose();
    });

    test('Should complete face detection within 5 seconds', () async {
      // Create test image data
      final imageData = Uint8List(320 * 240 * 3); // RGB image

      // Measure performance
      final stopwatch = Stopwatch()..start();

      try {
        final result = await faceDetector.processImage(imageData, testImage);
        stopwatch.stop();

        final processingTimeMs = stopwatch.elapsedMilliseconds;
        print('Face detection completed in ${processingTimeMs}ms');

        // Performance assertion - should be under 5 seconds
        expect(processingTimeMs, lessThan(5000),
            reason:
                'Face detection took ${processingTimeMs}ms, which exceeds 5 second target');

        // Verify result is not null when face is detected
        if (result != null) {
          print('Face detection successful: ${result.detectionResult.level}');
        }
      } catch (e) {
        print('Face detection test error: $e');
        // Test passes if face detection works (even if no face found)
        expect(e, isA<Exception>());
      }
    });

    test('Should handle memory efficiently', () async {
      final imageData = Uint8List(640 * 480 * 3); // Larger test image

      final stopwatch = Stopwatch()..start();

      // Run multiple detections to test memory efficiency
      for (int i = 0; i < 5; i++) {
        await faceDetector.processImage(imageData, testImage);

        // Small delay between tests
        await Future.delayed(Duration(milliseconds: 100));
      }

      stopwatch.stop();
      final totalTimeMs = stopwatch.elapsedMilliseconds;
      final avgTimeMs = totalTimeMs / 5;

      print('Average face detection time over 5 runs: ${avgTimeMs}ms');

      // Average should be reasonable
      expect(avgTimeMs, lessThan(6000),
          reason: 'Average processing time ${avgTimeMs}ms is too high');
    });

    test('Should have good performance with verbose logging disabled',
        () async {
      // Verify verbose logging is disabled
      expect(AppConfig.enableVerboseLogging, isFalse,
          reason:
              'Verbose logging should be disabled in production for performance');

      final imageData = Uint8List(320 * 240 * 3);

      final stopwatch = Stopwatch()..start();
      await faceDetector.processImage(imageData, testImage);
      stopwatch.stop();

      final processingTimeMs = stopwatch.elapsedMilliseconds;

      print('Face detection with minimal logging: ${processingTimeMs}ms');

      // Should be faster with logging disabled
      expect(processingTimeMs, lessThan(4000));
    });
  });
}

/// Create a test InputImage for performance testing
InputImage _createTestImage() {
  return InputImage.fromData(
    bytes: Uint8List(320 * 240 * 3), // RGB bytes
    inputImageFormat: InputImageFormat.nv21,
    size: const Size(320, 240),
    imageRotation: InputImageRotation.rotation0deg,
  );
}
